import Foundation

func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double { v < a ? a : (v > b ? b : v) }

func easeInOutCubic(_ t: Double) -> Double {
    t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
}

func normDeg(_ d: Double) -> Double {
    var x = d.truncatingRemainder(dividingBy: 360)
    if x > 180 { x -= 360 }
    if x < -180 { x += 360 }
    return x
}

func distXZ(_ x: Double, _ z: Double) -> Double { (x * x + z * z).squareRoot() }

func dirVector(_ dir: String, _ yawDeg: Double) -> (x: Double, y: Double, z: Double) {
    let y = yawDeg * .pi / 180
    let f = (x: -sin(y), y: 0.0, z: -cos(y))
    let r = (x: cos(y), y: 0.0, z: -sin(y))
    switch dir {
    case "forward": return f
    case "back":    return (x: -f.x, y: 0, z: -f.z)
    case "right":   return r
    case "left":    return (x: -r.x, y: 0, z: -r.z)
    case "up":      return (x: 0, y: 1, z: 0)
    case "down":    return (x: 0, y: -1, z: 0)
    default:        return (x: 0, y: 0, z: 0)
    }
}

func ledRGB(_ name: String) -> [Int] {
    let map: [String: [Int]] = [
        "off": [0, 0, 0], "red": [255, 0, 0], "green": [0, 255, 0], "blue": [0, 0, 255],
        "cyan": [0, 255, 255], "yellow": [255, 255, 0], "purple": [160, 0, 255],
        "white": [255, 255, 255], "orange": [255, 120, 0], "pink": [255, 60, 160]
    ]
    return map[name] ?? [0, 0, 0]
}

struct Obstacle {
    var x: Double, z: Double, w: Double, d: Double, h: Double
}

struct RingSpec {
    var x: Double, y: Double, z: Double, rotY: Double
}

func rayObstacleDistance(_ px: Double, _ py: Double, _ pz: Double,
                         _ dx: Double, _ dz: Double,
                         _ obstacles: [Obstacle], _ maxRange: Double) -> Double {
    var best = maxRange
    for o in obstacles {
        if py > o.h { continue }
        let minX = o.x - o.w / 2, maxX = o.x + o.w / 2
        let minZ = o.z - o.d / 2, maxZ = o.z + o.d / 2
        var t0 = 0.0, t1 = maxRange
        if abs(dx) < 1e-9 {
            if px < minX || px > maxX { continue }
        } else {
            var ta = (minX - px) / dx, tb = (maxX - px) / dx
            if ta > tb { swap(&ta, &tb) }
            t0 = max(t0, ta); t1 = min(t1, tb)
        }
        if abs(dz) < 1e-9 {
            if pz < minZ || pz > maxZ { continue }
        } else {
            var ta = (minZ - pz) / dz, tb = (maxZ - pz) / dz
            if ta > tb { swap(&ta, &tb) }
            t0 = max(t0, ta); t1 = min(t1, tb)
        }
        if t0 <= t1 && t1 > 0 { best = min(best, max(0, t0)) }
    }
    return best
}

func pointInObstacle(_ px: Double, _ py: Double, _ pz: Double,
                     _ obstacles: [Obstacle], _ margin: Double = 0) -> Bool {
    for o in obstacles {
        if py > o.h + margin { continue }
        if abs(px - o.x) <= o.w / 2 + margin && abs(pz - o.z) <= o.d / 2 + margin { return true }
    }
    return false
}

enum Cmd {
    case takeoff, land, emergency, stop
    case move(dir: String, dist: Double)
    case rotate(way: String, deg: Double)
    case flip(way: String)
    case hover(sec: Double)
    case speed(value: Double)
    case goTo(x: Double, y: Double, z: Double, speed: Double)
    case curve(x1: Double, y1: Double, z1: Double, x2: Double, y2: Double, z2: Double, speed: Double)
    case led(color: String)
    case ledRGBValues(r: Double, g: Double, b: Double)
}

private func r0(_ v: Double) -> Int { Int(v.rounded()) }

func telloCommand(_ c: Cmd) -> String {
    switch c {
    case .takeoff:   return "takeoff"
    case .land:      return "land"
    case .emergency: return "emergency"
    case .stop:      return "stop"
    case .move(let dir, let dist):  return "\(dir) \(r0(dist))"
    case .rotate(let way, let deg): return (way == "cw" ? "cw " : "ccw ") + "\(r0(deg))"
    case .flip(let way):   return "flip \(way)"
    case .hover(let sec):  return "delay \(fmtNum(sec))"
    case .speed(let v):    return "speed \(r0(v))"
    case .goTo(let x, let y, let z, let s): return "go \(r0(x)) \(r0(y)) \(r0(z)) \(r0(s))"
    case .curve(let x1, let y1, let z1, let x2, let y2, let z2, let s):
        let parts: [Int] = [r0(x1), r0(y1), r0(z1), r0(x2), r0(y2), r0(z2), r0(s)]
        return "curve " + parts.map(String.init).joined(separator: " ")
    case .led(let color):
        return "EXT led " + ledRGB(color).map(String.init).joined(separator: " ")
    case .ledRGBValues(let r, let g, let b):
        return "EXT led \(r0(r)) \(r0(g)) \(r0(b))"
    }
}

func pyCommand(_ c: Cmd) -> String {
    switch c {
    case .takeoff:   return "tello.takeoff()"
    case .land:      return "tello.land()"
    case .emergency: return "tello.emergency()"
    case .stop:      return "tello.send_control_command(\"stop\")"
    case .hover(let sec): return "time.sleep(\(fmtNum(sec)))"
    case .speed(let v):   return "tello.set_speed(\(fmtNum(v)))"
    case .flip(let way):
        let names = ["f": "forward", "b": "back", "l": "left", "r": "right"]
        return "tello.flip_" + (names[way] ?? "forward") + "()"
    case .rotate(let way, let deg):
        return "tello.rotate_" + (way == "cw" ? "clockwise" : "counter_clockwise") + "(\(fmtNum(deg)))"
    case .move(let dir, let dist):
        return "tello.move_\(dir)(\(fmtNum(dist)))"
    case .goTo(let x, let y, let z, let s):
        return "tello.go_xyz_speed(\(fmtNum(x)), \(fmtNum(y)), \(fmtNum(z)), \(fmtNum(s)))"
    case .curve(let x1, let y1, let z1, let x2, let y2, let z2, let s):
        let args: [String] = [x1, y1, z1, x2, y2, z2, s].map(fmtNum)
        return "tello.curve_xyz_speed(" + args.joined(separator: ", ") + ")"
    case .led(let color):
        return "tello.send_expansion_command(\"led " + ledRGB(color).map(String.init).joined(separator: " ") + "\")"
    case .ledRGBValues:
        return "tello.send_expansion_command(\"led %d %d %d\")"
    }
}

func fmtNum(_ v: Double) -> String {
    if v == v.rounded() && abs(v) < 1e15 { return String(Int(v.rounded())) }
    return String(v)
}

let PY_SENSOR: [String: String] = [
    "height": "tello.get_height()", "battery": "tello.get_battery()", "time": "tello.get_flight_time()",
    "temp": "tello.get_temperature()", "tof": "tello.get_distance_tof()", "yaw": "tello.get_yaw()",
    "pitch": "tello.get_pitch()", "roll": "tello.get_roll()", "speed": "tello.get_speed_x()",
    "pos_x": "position_x", "pos_y": "position_y", "pos_z": "position_z",
    "dist_home": "distance_from_home", "front": "front_distance"
]
