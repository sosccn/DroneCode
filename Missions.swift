import Foundation

struct FlightLog {
    var tookOff = false
    var landed = false
    var crashed = false
    var errors = 0
    var flips = 0
    var ledUsed = false
    var maxAlt: Double = 0
    var maxDist: Double = 0
    var endDist: Double = 0
    var minFront: Double = 9999
    var rings: [Bool] = []
    var blocks: [String] = []
}

struct CheckResult {
    var ok: Bool
    var key: String
    var args: [CustomStringConvertible] = []
}

struct Mission: Identifiable {
    let id: String
    let rings: [RingSpec]
    let obstacles: [Obstacle]
    let example: () -> [BNode]
    let check: (FlightLog) -> CheckResult

    var name: String { MISSION_TEXT[id]?.name[CURRENT_LANG.rawValue] ?? id }
    var goal: String { MISSION_TEXT[id]?.goal[CURRENT_LANG.rawValue] ?? "" }
    var brief: String { MISSION_TEXT[id]?.brief[CURRENT_LANG.rawValue] ?? "" }
}

private func r(_ v: Double) -> Int { Int(v.rounded()) }

private let mission_basic: Mission = Mission(id: "basic", rings: [], obstacles: [],
        example: {
            [BNode("drone_takeoff"),
             BNode("drone_hover", nums: ["SEC": 2]),
             BNode("drone_land")]
        },
        check: { log in
            if !log.tookOff { return CheckResult(ok: false, key: "chk.noTakeoff") }
            if !log.landed  { return CheckResult(ok: false, key: "chk.noLand") }
            if log.errors > 0 { return CheckResult(ok: false, key: "chk.hasErrors") }
            return CheckResult(ok: true, key: "chk.pass")
        })

private let mission_line: Mission = Mission(id: "line", rings: [], obstacles: [],
        example: {
            [BNode("drone_takeoff"),
             BNode("drone_move", fields: ["DIR": "forward"], nums: ["DIST": 100]),
             BNode("drone_move", fields: ["DIR": "back"], nums: ["DIST": 100]),
             BNode("drone_land")]
        },
        check: { log in
            if !log.tookOff { return CheckResult(ok: false, key: "chk.noTakeoff") }
            if log.maxDist < 90 { return CheckResult(ok: false, key: "chk.tooShort", args: [r(log.maxDist)]) }
            if log.endDist > 40 { return CheckResult(ok: false, key: "chk.notBack", args: [r(log.endDist)]) }
            if !log.landed { return CheckResult(ok: false, key: "chk.noLand") }
            return CheckResult(ok: true, key: "chk.pass")
        })

private let mission_square: Mission = Mission(id: "square",
        rings: [RingSpec(x: 0, y: 100, z: -75, rotY: 0),
                RingSpec(x: 75, y: 100, z: -150, rotY: 90),
                RingSpec(x: 150, y: 100, z: -75, rotY: 0),
                RingSpec(x: 75, y: 100, z: 0, rotY: 90)],
        obstacles: [],
        example: {
            let loop = BNode("controls_repeat_ext", values: ["TIMES": num(4)],
                             body: ["DO": [BNode("drone_move", fields: ["DIR": "forward"], nums: ["DIST": 150]),
                                           BNode("drone_rotate", fields: ["WAY": "cw"], nums: ["DEG": 90])]])
            return [BNode("drone_takeoff"), loop, BNode("drone_land")]
        },
        check: { log in
            let got = log.rings.filter { $0 }.count
            if got < 4 { return CheckResult(ok: false, key: "chk.rings", args: [got, 4]) }
            if !log.blocks.contains("controls_repeat_ext") { return CheckResult(ok: false, key: "chk.noLoop") }
            if !log.landed { return CheckResult(ok: false, key: "chk.noLand") }
            return CheckResult(ok: true, key: "chk.pass")
        })

private let mission_course: Mission = Mission(id: "course",
        rings: [RingSpec(x: 0, y: 60, z: -120, rotY: 0),
                RingSpec(x: 0, y: 160, z: -240, rotY: 0),
                RingSpec(x: -120, y: 160, z: -240, rotY: 90)],
        obstacles: [],
        example: {
            [BNode("drone_takeoff"),
             BNode("drone_move", fields: ["DIR": "down"], nums: ["DIST": 40]),
             BNode("drone_move", fields: ["DIR": "forward"], nums: ["DIST": 120]),
             BNode("drone_move", fields: ["DIR": "up"], nums: ["DIST": 100]),
             BNode("drone_move", fields: ["DIR": "forward"], nums: ["DIST": 120]),
             BNode("drone_rotate", fields: ["WAY": "ccw"], nums: ["DEG": 90]),
             BNode("drone_move", fields: ["DIR": "forward"], nums: ["DIST": 120]),
             BNode("drone_land")]
        },
        check: { log in
            let got = log.rings.filter { $0 }.count
            if got < 3 { return CheckResult(ok: false, key: "chk.rings", args: [got, 3]) }
            if !log.landed { return CheckResult(ok: false, key: "chk.noLand") }
            return CheckResult(ok: true, key: "chk.pass")
        })

private let mission_show: Mission = Mission(id: "show", rings: [], obstacles: [],
        example: {
            [BNode("drone_takeoff"),
             BNode("drone_move", fields: ["DIR": "up"], nums: ["DIST": 50]),
             BNode("drone_led", fields: ["COLOR": "purple"]),
             BNode("drone_flip", fields: ["WAY": "f"]),
             BNode("drone_hover", nums: ["SEC": 1]),
             BNode("drone_land")]
        },
        check: { log in
            if log.flips < 1 { return CheckResult(ok: false, key: "chk.noFlip") }
            if !log.ledUsed { return CheckResult(ok: false, key: "chk.noLed") }
            if !log.landed { return CheckResult(ok: false, key: "chk.noLand") }
            return CheckResult(ok: true, key: "chk.pass")
        })

private let mission_sensor: Mission = Mission(id: "sensor", rings: [],
        obstacles: [Obstacle(x: 0, z: -300, w: 420, d: 20, h: 260),
                    Obstacle(x: -260, z: -140, w: 20, d: 320, h: 200),
                    Obstacle(x: 260, z: -140, w: 20, d: 320, h: 200)],
        example: {
            let loop = BNode("controls_whileUntil", fields: ["MODE": "UNTIL"],
                             values: ["BOOL": obstacleAhead(100)],
                             body: ["DO": [BNode("drone_move", fields: ["DIR": "forward"], nums: ["DIST": 20])]])
            return [BNode("drone_takeoff"),
                    loop,
                    BNode("drone_print", values: ["TEXT": textNode("wall detected")]),
                    BNode("drone_rotate", fields: ["WAY": "cw"], nums: ["DEG": 90]),
                    BNode("drone_land")]
        },
        check: { log in
            if log.crashed { return CheckResult(ok: false, key: "chk.crashed") }
            if !log.tookOff { return CheckResult(ok: false, key: "chk.noTakeoff") }
            let usedCond = log.blocks.contains("controls_whileUntil")
                || log.blocks.contains("controls_if")
                || log.blocks.contains("drone_wait_until")
            if !usedCond { return CheckResult(ok: false, key: "chk.noWhile") }
            if log.minFront < 60 || log.minFront > 140 {
                return CheckResult(ok: false, key: "chk.stopFar", args: [r(log.minFront)])
            }
            if !log.landed { return CheckResult(ok: false, key: "chk.noLand") }
            return CheckResult(ok: true, key: "chk.pass")
        })

private let mission_variables: Mission = Mission(id: "variables", rings: [], obstacles: [],
        example: {
            let inner = BNode("drone_move_by", fields: ["DIR": "up"],
                              values: ["DISTANCE": arithmetic(variableGet("i"), "MULTIPLY", num(20))])
            let loop = BNode("controls_for", fields: ["VAR": "i"],
                             values: ["FROM": num(1), "TO": num(4), "BY": num(1)],
                             body: ["DO": [inner]])
            return [BNode("drone_takeoff"), loop,
                    BNode("drone_hover", nums: ["SEC": 1]),
                    BNode("drone_land")]
        },
        check: { log in
            if !log.blocks.contains("controls_for") { return CheckResult(ok: false, key: "chk.noFor") }
            if log.maxAlt < 250 { return CheckResult(ok: false, key: "chk.lowAlt", args: [r(log.maxAlt)]) }
            if !log.landed { return CheckResult(ok: false, key: "chk.noLand") }
            return CheckResult(ok: true, key: "chk.pass")
        })

private let mission_free: Mission = Mission(id: "free", rings: [], obstacles: [],
        example: {
            [BNode("drone_takeoff"),
             BNode("drone_speed", nums: ["VALUE": 80]),
             BNode("drone_led", fields: ["COLOR": "cyan"]),
             BNode("drone_goto", nums: ["X": 120, "Y": 180, "Z": -140, "SPEED": 70]),
             BNode("drone_curve", nums: ["X1": 0, "Y1": 180, "Z1": -260,
                                         "X2": -120, "Y2": 140, "Z2": -120, "SPEED": 60]),
             BNode("drone_rotate", fields: ["WAY": "ccw"], nums: ["DEG": 180]),
             BNode("drone_land")]
        },
        check: { _ in CheckResult(ok: true, key: "chk.pass") })

let MISSIONS: [Mission] = [
    mission_basic, mission_line, mission_square, mission_course, mission_show, mission_sensor, mission_variables, mission_free
]

func findMission(_ id: String) -> Mission {
    MISSIONS.first(where: { $0.id == id }) ?? MISSIONS[0]
}
