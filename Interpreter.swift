import SwiftUI
import QuartzCore

enum FlowSignal: Error { case breakLoop, continueLoop }

@MainActor
extension AppModel {

    func scaled(_ ms: Double) -> Double { max(70, ms / rate) }

    func tick() async {
        while paused && !abort {
            try? await Task.sleep(nanoseconds: 16_000_000)
        }
        try? await Task.sleep(nanoseconds: 16_000_000)
    }

    func tween(_ ms: Double, _ step: (Double, Double) -> Void) async {
        let dur = ms / 1000
        if dur <= 0 { step(1, 1); return }
        var t0 = CACurrentMediaTime()
        var last = t0
        while true {
            if abort { return }
            try? await Task.sleep(nanoseconds: 16_000_000)
            let now = CACurrentMediaTime()
            if paused { t0 += now - last; last = now; continue }
            last = now
            let p = min(1, (now - t0) / dur)
            step(easeInOutCubic(p), p)
            arena?.sync(sim)
            if p >= 1 { return }
        }
    }

    func frontDistance() -> Double {
        let y = sim.yaw * .pi / 180
        return rayObstacleDistance(sim.x, sim.y, sim.z, -sin(y), -cos(y), activeObstacles, 500)
    }

    func sampleFlight() {
        if sim.y > flight.maxAlt { flight.maxAlt = sim.y }
        let d = distXZ(sim.x, sim.z)
        if d > flight.maxDist { flight.maxDist = d }

        if !activeObstacles.isEmpty {
            let fd = frontDistance()
            if sim.flying && fd < flight.minFront { flight.minFront = fd }
            if !flight.crashed && pointInObstacle(sim.x, sim.y, sim.z, activeObstacles, 12) {
                flight.crashed = true
                flight.errors += 1
                logLine("log.crash", kind: "err")
            }
        }

        if abs(sim.x - lastTrail.x) + abs(sim.y - lastTrail.y) + abs(sim.z - lastTrail.z) > 1.5 {
            lastTrail = (sim.x, sim.y, sim.z)
            arena?.addTrailPoint(x: sim.x, y: sim.y, z: sim.z)
        }

        for (i, r) in activeRings.enumerated() {
            if i < flight.rings.count && flight.rings[i] { continue }
            let dx = sim.x - r.x, dy = sim.y - r.y, dz = sim.z - r.z
            if (dx * dx + dy * dy + dz * dz).squareRoot() < 45 {
                if i < flight.rings.count { flight.rings[i] = true }
                arena?.markRingPassed(i)
                logLine("log.ring", [i + 1], kind: "sys")
            }
        }
    }

    func useBattery(_ seconds: Double, _ extra: Double = 0) {
        sim.flightTime += seconds
        sim.battery = clamp(sim.battery - seconds * 0.35 - extra, 0, 100)
        if sim.battery < 20 && !lowWarned {
            lowWarned = true
            logLine("log.lowbat", kind: "warn")
        }
    }

    func requireFlying(_ what: String) -> Bool {
        if !sim.flying {
            logLine("log.errNotFlying", [what], kind: "err")
            flagCurrent(t("log.errNotFlying", [what]))
            flight.errors += 1
            return false
        }
        return true
    }

    func flagCurrent(_ msg: String) {
        warnedBlock = runningBlock
        warnMessage = msg
    }

    func localFrame(_ vx: Double, _ vz: Double) -> (fwd: Double, right: Double) {
        let y = sim.yaw * .pi / 180
        let f = (x: -sin(y), z: -cos(y))
        let r = (x: cos(y), z: -sin(y))
        return (fwd: vx * f.x + vz * f.z, right: vx * r.x + vz * r.z)
    }

    func moveTo(_ tx: Double, _ ty: Double, _ tz: Double, _ ms: Double) async {
        let sx = sim.x, sy = sim.y, sz = sim.z
        let dxz = ((tx - sx) * (tx - sx) + (tz - sz) * (tz - sz)).squareRoot()
        let tilt = dxz > 0.01 ? localFrame((tx - sx) / dxz, (tz - sz) / dxz) : (fwd: 0.0, right: 0.0)
        let mag = min(1, dxz / 60)
        sim.moving = true
        useBattery(ms / 1000)
        await tween(ms) { e, _ in
            self.sim.x = sx + (tx - sx) * e
            self.sim.y = sy + (ty - sy) * e
            self.sim.z = sz + (tz - sz) * e
            let s = sin(e * .pi) * 0.3 * mag
            self.sim.pitch = -tilt.fwd * s
            self.sim.roll = -tilt.right * s
            self.sampleFlight()
        }
        if !abort { sim.x = tx; sim.y = ty; sim.z = tz }
        sim.pitch = 0; sim.roll = 0; sim.moving = false
        sampleFlight()
        arena?.sync(sim)
    }

    func curveTo(_ p1: (x: Double, y: Double, z: Double),
                 _ p2: (x: Double, y: Double, z: Double), _ ms: Double) async {
        let s = (x: sim.x, y: sim.y, z: sim.z)
        sim.moving = true
        useBattery(ms / 1000)
        await tween(ms) { e, _ in
            let u = 1 - e
            self.sim.x = u * u * s.x + 2 * u * e * p1.x + e * e * p2.x
            self.sim.y = u * u * s.y + 2 * u * e * p1.y + e * e * p2.y
            self.sim.z = u * u * s.z + 2 * u * e * p1.z + e * e * p2.z
            self.sim.roll = sin(e * .pi) * 0.22
            self.sampleFlight()
        }
        if !abort { sim.x = p2.x; sim.y = p2.y; sim.z = p2.z }
        sim.roll = 0; sim.moving = false
        sampleFlight()
        arena?.sync(sim)
    }

    func cmdTakeoff() async {
        if sim.flying { logLine("log.warnFlying", kind: "warn"); return }
        pushCmd(telloCommand(.takeoff))
        logLine("log.takeoff")
        sim.flying = true
        sim.statusKey = "status.takeoff"
        flight.tookOff = true
        await moveTo(sim.x, 100, sim.z, scaled(1700))
        sim.statusKey = "status.hover"
    }

    func cmdLand() async {
        if !sim.flying { logLine("log.warnGround", kind: "warn"); return }
        pushCmd(telloCommand(.land))
        logLine("log.land")
        sim.statusKey = "status.landing"
        await moveTo(sim.x, 0, sim.z, scaled(max(900, sim.y * 13)))
        sim.flying = false
        flight.landed = true
        sim.statusKey = "status.landed"
        logLine("log.landed")
    }

    func cmdEmergency() async {
        pushCmd(telloCommand(.emergency))
        logLine("log.emergency", kind: "err")
        sim.statusKey = "status.emergency"
        await moveTo(sim.x, 0, sim.z, scaled(420))
        sim.flying = false
    }

    func cmdStop() async {
        if !requireFlying("stop") { return }
        pushCmd(telloCommand(.stop))
        logLine("log.stop")
        sim.statusKey = "status.hover"
        await tween(scaled(350)) { _, _ in self.sampleFlight() }
    }

    func cmdHover(_ secIn: Double) async {
        let sec = clamp(secIn, 0.1, 60)
        pushCmd(telloCommand(.hover(sec: sec)))
        logLine("log.hover", [fmtNum(sec)])
        sim.statusKey = "status.hover"
        useBattery(sec)
        await tween(scaled(sec * 1000)) { _, _ in self.sampleFlight() }
    }

    func cmdMove(_ dir: String, _ distIn: Double) async {
        if !requireFlying("fly " + dir) { return }
        let dist = clamp(distIn, 20, 500)
        let v = dirVector(dir, sim.yaw)
        let tx = sim.x + v.x * dist
        var ty = sim.y + v.y * dist
        let tz = sim.z + v.z * dist
        if ty < 20 { logLine("log.warnFloor", kind: "warn"); ty = 20 }
        if ty > 500 { logLine("log.warnCeiling", kind: "warn"); ty = 500 }
        pushCmd(telloCommand(.move(dir: dir, dist: dist)))
        logLine("log.move", [dir, Int(dist.rounded()), Int(sim.speed.rounded())])
        sim.statusKey = "status.move"
        await moveTo(tx, ty, tz, scaled(max(0.35, dist / max(10, sim.speed)) * 1000))
        sim.statusKey = "status.hover"
    }

    func cmdGoto(_ x: Double, _ yIn: Double, _ z: Double, _ speedIn: Double) async {
        if !requireFlying("go to") { return }
        let y = clamp(yIn, 20, 500)
        let speed = clamp(speedIn, 10, 100)
        let dx = x - sim.x, dy = y - sim.y, dz = z - sim.z
        let lf = localFrame(dx, dz)
        pushCmd(telloCommand(.goTo(x: lf.fwd, y: -lf.right, z: dy, speed: speed)))
        logLine("log.goto", [Int(x.rounded()), Int(y.rounded()), Int(z.rounded())])
        sim.statusKey = "status.goto"
        let dist = (dx * dx + dy * dy + dz * dz).squareRoot()
        await moveTo(x, y, z, scaled(max(420, dist / speed * 1000)))
        sim.statusKey = "status.hover"
    }

    func cmdCurve(_ x1: Double, _ y1: Double, _ z1: Double,
                  _ x2: Double, _ y2: Double, _ z2: Double, _ speedIn: Double) async {
        if !requireFlying("fly curve") { return }
        let speed = clamp(speedIn, 10, 60)
        let lf1 = localFrame(x1 - sim.x, z1 - sim.z)
        let lf2 = localFrame(x2 - sim.x, z2 - sim.z)
        pushCmd(telloCommand(.curve(x1: lf1.fwd, y1: -lf1.right, z1: y1 - sim.y,
                                    x2: lf2.fwd, y2: -lf2.right, z2: y2 - sim.y, speed: speed)))
        logLine("log.curve", [Int(x1.rounded()), Int(y1.rounded()), Int(z1.rounded()),
                              Int(x2.rounded()), Int(y2.rounded()), Int(z2.rounded())])
        sim.statusKey = "status.curve"
        let len = (pow(x2 - sim.x, 2) + pow(y2 - sim.y, 2) + pow(z2 - sim.z, 2)).squareRoot() * 1.3
        await curveTo((x: x1, y: clamp(y1, 20, 500), z: z1),
                      (x: x2, y: clamp(y2, 20, 500), z: z2),
                      scaled(max(700, len / speed * 1000)))
        sim.statusKey = "status.hover"
    }

    func cmdRotate(_ way: String, _ degIn: Double) async {
        if !requireFlying("rotate") { return }
        let deg = clamp(degIn, 1, 360)
        pushCmd(telloCommand(.rotate(way: way, deg: deg)))
        logLine("log.rotate", [way == "cw" ? "clockwise" : "counter-clockwise", Int(deg.rounded())])
        sim.statusKey = "status.rotate"
        let s = sim.yaw
        let target = sim.yaw + (way == "cw" ? -deg : deg)
        useBattery(deg / 120)
        await tween(scaled(max(320, deg / 90 * 850))) { e, _ in
            self.sim.yaw = s + (target - s) * e
            self.sim.roll = (way == "cw" ? -1 : 1) * sin(e * .pi) * 0.12
            self.sampleFlight()
        }
        if !abort { sim.yaw = target }
        sim.roll = 0
        sim.statusKey = "status.hover"
    }

    func cmdFlip(_ way: String) async {
        if !requireFlying("flip") { return }
        if sim.y < 80 {
            logLine("log.errFlipLow", [Int(sim.y.rounded())], kind: "err")
            flagCurrent(t("log.errFlipLow", [Int(sim.y.rounded())]))
            flight.errors += 1
            return
        }
        pushCmd(telloCommand(.flip(way: way)))
        let names = ["f": "forward", "b": "back", "l": "left", "r": "right"]
        logLine("log.flip", [names[way] ?? way])
        sim.statusKey = "status.flip"
        let y0 = sim.y
        useBattery(1, 1.5)
        await tween(scaled(950)) { e, _ in
            let a = e * .pi * 2
            self.sim.flipPitch = (way == "f" ? -a : (way == "b" ? a : 0))
            self.sim.flipRoll = (way == "l" ? a : (way == "r" ? -a : 0))
            self.sim.y = y0 + sin(e * .pi) * 18
            self.sampleFlight()
        }
        sim.flipPitch = 0; sim.flipRoll = 0
        if !abort { sim.y = y0 }
        flight.flips += 1
        sim.statusKey = "status.hover"
    }

    func cmdSpeed(_ v: Double) {
        sim.speed = clamp(v, 10, 100)
        pushCmd(telloCommand(.speed(value: sim.speed)))
        logLine("log.speed", [Int(sim.speed.rounded())])
    }

    func cmdLed(_ color: String) {
        sim.led = color
        sim.ledRGBv = ledRGB(color)
        pushCmd(telloCommand(.led(color: color)))
        logLine("log.led", [color])
        if color != "off" { flight.ledUsed = true }
        arena?.updateLED(sim.ledRGBv)
    }

    func cmdLedRGB(_ rIn: Double, _ gIn: Double, _ bIn: Double) {
        let r = clamp(rIn, 0, 255), g = clamp(gIn, 0, 255), b = clamp(bIn, 0, 255)
        sim.led = "rgb"
        sim.ledRGBv = [Int(r.rounded()), Int(g.rounded()), Int(b.rounded())]
        pushCmd(telloCommand(.ledRGBValues(r: r, g: g, b: b)))
        logLine("log.ledrgb", [Int(r.rounded()), Int(g.rounded()), Int(b.rounded())])
        if r + g + b > 0 { flight.ledUsed = true }
        arena?.updateLED(sim.ledRGBv)
    }

    func cmdWaitUntil(_ b: BNode) async {
        logLine("log.waitUntil", kind: "sys")
        sim.statusKey = "status.waiting"
        let t0 = CACurrentMediaTime()
        let budget = 20.0 / rate
        while !abort {
            if truth(evalValue(b.values["COND"])) { break }
            if CACurrentMediaTime() - t0 > budget {
                logLine("log.waitTimeout", kind: "warn")
                break
            }
            useBattery(0.016)
            sampleFlight()
            await tick()
        }
        sim.statusKey = "status.hover"
    }

    func sensorValue(_ name: String) -> Double {
        switch name {
        case "height":    return (sim.y).rounded()
        case "battery":   return (sim.battery).rounded()
        case "time":      return (sim.flightTime).rounded()
        case "temp":      return (25 + (100 - sim.battery) * 0.15).rounded()
        case "tof":       return (sim.y + 10).rounded()
        case "yaw":       return normDeg(sim.yaw).rounded()
        case "pitch":     return (sim.pitch * 180 / .pi).rounded()
        case "roll":      return (sim.roll * 180 / .pi).rounded()
        case "speed":     return (sim.speed).rounded()
        case "pos_x":     return (sim.x).rounded()
        case "pos_y":     return (sim.y).rounded()
        case "pos_z":     return (sim.z).rounded()
        case "dist_home": return distXZ(sim.x, sim.z).rounded()
        case "front":     return frontDistance().rounded()
        default:          return 0
        }
    }

    func truth(_ v: Double?) -> Bool {
        guard let v = v else { return false }
        return v != 0
    }

    func evalValue(_ b: BNode?, _ def: Double = 0) -> Double {
        guard let b = b else { return def }
        switch b.type {
        case "math_number":
            return b.nums["NUM"] ?? 0
        case "math_arithmetic":
            let a = evalValue(b.values["A"], 0)
            let c = evalValue(b.values["B"], 0)
            switch b.fields["OP"] ?? "ADD" {
            case "ADD": return a + c
            case "MINUS": return a - c
            case "MULTIPLY": return a * c
            case "DIVIDE": return c == 0 ? 0 : a / c
            case "POWER": return pow(a, c)
            default: return 0
            }
        case "logic_boolean":
            return (b.fields["BOOL"] ?? "TRUE") == "TRUE" ? 1 : 0
        case "logic_negate":
            return truth(evalValue(b.values["BOOL"])) ? 0 : 1
        case "logic_operation":
            let la = truth(evalValue(b.values["A"]))
            let lb = truth(evalValue(b.values["B"]))
            return ((b.fields["OP"] ?? "AND") == "AND" ? (la && lb) : (la || lb)) ? 1 : 0
        case "logic_compare":
            let a = evalValue(b.values["A"], 0)
            let c = evalValue(b.values["B"], 0)
            switch b.fields["OP"] ?? "EQ" {
            case "EQ":  return a == c ? 1 : 0
            case "NEQ": return a != c ? 1 : 0
            case "LT":  return a < c ? 1 : 0
            case "LTE": return a <= c ? 1 : 0
            case "GT":  return a > c ? 1 : 0
            case "GTE": return a >= c ? 1 : 0
            default: return 0
            }
        case "variables_get":
            return vars[b.fields["VAR"] ?? "item"] ?? 0
        case "drone_get":
            return sensorValue(b.fields["SENSOR"] ?? "height")
        case "drone_is_flying":
            return sim.flying ? 1 : 0
        case "drone_obstacle_ahead":
            let lim = evalValue(b.values["DIST"], 100)
            return frontDistance() < lim ? 1 : 0
        case "text":
            return Double(b.fields["TEXT"] ?? "") ?? 0
        default:
            return def
        }
    }

    func evalText(_ b: BNode?) -> String {
        guard let b = b else { return "" }
        if b.type == "text" { return b.fields["TEXT"] ?? "" }
        return fmtNum(evalValue(b))
    }

    func runLoopBody(_ inner: [BNode]) async -> String {
        do {
            try await execChain(inner, 0)
        } catch FlowSignal.breakLoop {
            return "BREAK"
        } catch {
            return "CONTINUE"
        }
        return "OK"
    }

    func execChain(_ list: [BNode], _ depth: Int) async throws {
        for b in list {
            if abort { return }
            try await execBlock(b, depth)
        }
    }

    func execBlock(_ b: BNode, _ depth: Int) async throws {
        if abort { return }
        commands += 1
        if commands > CMD_LIMIT {
            logLine("log.limit", [CMD_LIMIT], kind: "warn")
            abort = true
            return
        }
        runningBlock = b.id
        flight.blocks.append(b.type)

        switch b.type {
        case "drone_takeoff":   await cmdTakeoff()
        case "drone_land":      await cmdLand()
        case "drone_emergency": await cmdEmergency()
        case "drone_stop":      await cmdStop()
        case "drone_hover":     await cmdHover(b.nums["SEC"] ?? 2)
        case "drone_speed":     cmdSpeed(b.nums["VALUE"] ?? 50)
        case "drone_move":      await cmdMove(b.fields["DIR"] ?? "forward", b.nums["DIST"] ?? 100)
        case "drone_move_by":   await cmdMove(b.fields["DIR"] ?? "forward", evalValue(b.values["DISTANCE"], 50))
        case "drone_goto":      await cmdGoto(b.nums["X"] ?? 0, b.nums["Y"] ?? 100,
                                              b.nums["Z"] ?? 0, b.nums["SPEED"] ?? 60)
        case "drone_curve":     await cmdCurve(b.nums["X1"] ?? 0, b.nums["Y1"] ?? 100, b.nums["Z1"] ?? 0,
                                               b.nums["X2"] ?? 0, b.nums["Y2"] ?? 100, b.nums["Z2"] ?? 0,
                                               b.nums["SPEED"] ?? 60)
        case "drone_rotate":    await cmdRotate(b.fields["WAY"] ?? "cw", b.nums["DEG"] ?? 90)
        case "drone_rotate_by": await cmdRotate(b.fields["WAY"] ?? "cw", evalValue(b.values["DEGREES"], 90))
        case "drone_flip":      await cmdFlip(b.fields["WAY"] ?? "f")
        case "drone_led":       cmdLed(b.fields["COLOR"] ?? "red")
        case "drone_led_rgb":   cmdLedRGB(evalValue(b.values["R"], 0),
                                          evalValue(b.values["G"], 0),
                                          evalValue(b.values["B"], 0))
        case "drone_print":     logLine("log.print", [evalText(b.values["TEXT"])], kind: "sys")
        case "drone_wait_until": await cmdWaitUntil(b)

        case "controls_if":
            var done = false
            var n = 0
            while let cond = b.values["IF\(n)"] {
                if truth(evalValue(cond)) {
                    try await execChain(b.body["DO\(n)"] ?? [], depth)
                    done = true
                    break
                }
                n += 1
            }
            if !done, let els = b.body["ELSE"], !els.isEmpty {
                try await execChain(els, depth)
            }

        case "controls_repeat_ext":
            let n = Int(clamp(evalValue(b.values["TIMES"], 1).rounded(.down), 0, Double(LOOP_LIMIT)))
            let inner = b.body["DO"] ?? []
            if inner.isEmpty { logLine("log.loopEmpty", kind: "warn"); break }
            logLine("log.loop", [n], kind: "sys")
            for _ in 0..<n {
                if abort { return }
                if await runLoopBody(inner) == "BREAK" { break }
                await tick()
            }

        case "controls_whileUntil":
            let untilMode = (b.fields["MODE"] ?? "WHILE") == "UNTIL"
            let inner = b.body["DO"] ?? []
            var guardCount = 0
            while !abort {
                var cond = truth(evalValue(b.values["BOOL"]))
                if untilMode { cond = !cond }
                if !cond { break }
                guardCount += 1
                if guardCount > LOOP_LIMIT {
                    logLine("log.limit", [LOOP_LIMIT], kind: "warn")
                    break
                }
                if await runLoopBody(inner) == "BREAK" { break }
                await tick()
            }

        case "controls_for":
            let vname = b.fields["VAR"] ?? "i"
            let from = evalValue(b.values["FROM"], 1)
            let to = evalValue(b.values["TO"], 1)
            var by = abs(evalValue(b.values["BY"], 1))
            if by == 0 { by = 1 }
            let inner = b.body["DO"] ?? []
            var count = 0
            if from <= to {
                var x = from
                while x <= to {
                    count += 1
                    if abort || count > LOOP_LIMIT { break }
                    vars[vname] = x
                    if await runLoopBody(inner) == "BREAK" { break }
                    await tick()
                    x += by
                }
            } else {
                var x = from
                while x >= to {
                    count += 1
                    if abort || count > LOOP_LIMIT { break }
                    vars[vname] = x
                    if await runLoopBody(inner) == "BREAK" { break }
                    await tick()
                    x -= by
                }
            }

        case "controls_flow_statements":
            throw (b.fields["FLOW"] ?? "BREAK") == "CONTINUE" ? FlowSignal.continueLoop : FlowSignal.breakLoop

        case "variables_set":
            let sn = b.fields["VAR"] ?? "item"
            vars[sn] = evalValue(b.values["VALUE"], 0)
            logLine("log.varSet", [sn, fmtNum(vars[sn] ?? 0)], kind: "sys")

        case "math_change":
            let cn = b.fields["VAR"] ?? "item"
            vars[cn] = (vars[cn] ?? 0) + evalValue(b.values["DELTA"], 1)
            logLine("log.varSet", [cn, fmtNum(vars[cn] ?? 0)], kind: "sys")

        default:
            logLine("log.unknown", [b.type], kind: "warn")
        }
    }

    func onRun() async {
        if running { return }
        if program.isEmpty {
            showToast(t("toast.noProgram"), "bad")
            return
        }
        resetDrone(quiet: true)
        telloLines = []
        running = true
        abort = false
        paused = false
        commands = 0
        lowWarned = false
        setBadge("badge.flying", "")
        logLine("log.start", [mission.name], kind: "sys")

        do {
            try await execChain(program, 0)
        } catch {

        }

        runningBlock = nil
        running = false
        paused = false
        if flight.errors > 0 { logLine("log.blockWarn", kind: "warn") }

        if abort {
            sim.statusKey = "status.stopped"
            logLine("log.aborted", kind: "warn")
            setBadge("badge.notyet", "")
            return
        }
        logLine("log.done", kind: "sys")
        evaluateMission()
    }

    func onStop() {
        if running { abort = true }
    }

    func togglePause() {
        guard running else { return }
        paused.toggle()
        logLine(paused ? "log.paused" : "log.resumed", kind: "sys")
    }

    func evaluateMission() {
        flight.endDist = distXZ(sim.x, sim.z)
        var judged = flight
        judged.rings = Array(flight.rings.prefix(mission.rings.count))
        let res = mission.check(judged)
        if res.ok {
            setBadge("badge.pass", "pass")
            logLine(res.key, res.args, kind: "sys")
            showToast(t("badge.pass") + " - " + t(res.key, res.args), "good")
        } else {
            setBadge("badge.fail", "fail")
            logLine(res.key, res.args, kind: "warn")
            showToast(t(res.key, res.args), "bad")
        }
    }
}
