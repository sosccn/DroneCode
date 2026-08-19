import Foundation

func pyIndent(_ n: Int) -> String { String(repeating: "    ", count: max(0, n)) }

func pyStr(_ v: String) -> String {
    "\"" + v.replacingOccurrences(of: "\"", with: "\\\"") + "\""
}

func pyValue(_ b: BNode?) -> String {
    guard let b = b else { return "0" }
    switch b.type {
    case "math_number":
        return fmtNum(b.nums["NUM"] ?? 0)
    case "math_arithmetic":
        let ops = ["ADD": "+", "MINUS": "-", "MULTIPLY": "*", "DIVIDE": "/", "POWER": "**"]
        let op = ops[b.fields["OP"] ?? "ADD"] ?? "+"
        let lhs = pyValue(b.values["A"])
        let rhs = pyValue(b.values["B"])
        return "(\(lhs) \(op) \(rhs))"
    case "logic_boolean":
        return (b.fields["BOOL"] ?? "TRUE") == "TRUE" ? "True" : "False"
    case "logic_negate":
        return "not (" + pyValue(b.values["BOOL"]) + ")"
    case "logic_operation":
        let joiner = (b.fields["OP"] ?? "AND") == "AND" ? " and " : " or "
        let lhs = pyValue(b.values["A"])
        let rhs = pyValue(b.values["B"])
        return "(\(lhs)\(joiner)\(rhs))"
    case "logic_compare":
        let cops = ["EQ": "==", "NEQ": "!=", "LT": "<", "LTE": "<=", "GT": ">", "GTE": ">="]
        let op = cops[b.fields["OP"] ?? "EQ"] ?? "=="
        let lhs = pyValue(b.values["A"])
        let rhs = pyValue(b.values["B"])
        return "(\(lhs) \(op) \(rhs))"
    case "text":
        return pyStr(b.fields["TEXT"] ?? "")
    case "variables_get":
        return b.fields["VAR"] ?? "item"
    case "drone_get":
        return PY_SENSOR[b.fields["SENSOR"] ?? "height"] ?? "0"
    case "drone_is_flying":
        return "tello.is_flying"
    case "drone_obstacle_ahead":
        return "(front_distance() < " + pyValue(b.values["DIST"]) + ")"
    default:
        return "0"
    }
}

func pyStatement(_ b: BNode, _ ind: Int) -> [String] {
    var L: [String] = []
    let p = pyIndent(ind)
    switch b.type {
    case "drone_takeoff":   L.append(p + pyCommand(.takeoff))
    case "drone_land":      L.append(p + pyCommand(.land))
    case "drone_emergency": L.append(p + pyCommand(.emergency))
    case "drone_stop":      L.append(p + pyCommand(.stop))
    case "drone_hover":     L.append(p + pyCommand(.hover(sec: b.nums["SEC"] ?? 2)))
    case "drone_speed":     L.append(p + pyCommand(.speed(value: b.nums["VALUE"] ?? 50)))
    case "drone_move":
        L.append(p + pyCommand(.move(dir: b.fields["DIR"] ?? "forward", dist: b.nums["DIST"] ?? 100)))
    case "drone_move_by":
        let dir = b.fields["DIR"] ?? "forward"
        let dist = pyValue(b.values["DISTANCE"])
        L.append(p + "tello.move_\(dir)(int(\(dist)))")
    case "drone_goto":
        L.append(p + pyCommand(.goTo(x: b.nums["X"] ?? 0, y: b.nums["Y"] ?? 100,
                                     z: b.nums["Z"] ?? 0, speed: b.nums["SPEED"] ?? 60)))
    case "drone_curve":
        L.append(p + pyCommand(.curve(x1: b.nums["X1"] ?? 0, y1: b.nums["Y1"] ?? 0, z1: b.nums["Z1"] ?? 0,
                                      x2: b.nums["X2"] ?? 0, y2: b.nums["Y2"] ?? 0, z2: b.nums["Z2"] ?? 0,
                                      speed: b.nums["SPEED"] ?? 60)))
    case "drone_rotate":
        L.append(p + pyCommand(.rotate(way: b.fields["WAY"] ?? "cw", deg: b.nums["DEG"] ?? 90)))
    case "drone_rotate_by":
        let way = (b.fields["WAY"] ?? "cw") == "cw" ? "clockwise" : "counter_clockwise"
        let deg = pyValue(b.values["DEGREES"])
        L.append(p + "tello.rotate_\(way)(int(\(deg)))")
    case "drone_flip":
        L.append(p + pyCommand(.flip(way: b.fields["WAY"] ?? "f")))
    case "drone_led":
        L.append(p + pyCommand(.led(color: b.fields["COLOR"] ?? "red")))
    case "drone_led_rgb":
        let rr = pyValue(b.values["R"])
        let gg = pyValue(b.values["G"])
        let bb = pyValue(b.values["B"])
        L.append(p + "tello.send_expansion_command(\"led %d %d %d\" % (\(rr), \(gg), \(bb)))")
    case "drone_print":
        L.append(p + "print(" + pyValue(b.values["TEXT"]) + ")")
    case "drone_wait_until":
        let cond = pyValue(b.values["COND"])
        L.append(p + "while not (\(cond)):")
        L.append(pyIndent(ind + 1) + "time.sleep(0.1)")

    case "controls_if":
        var n = 0
        while let cond = b.values["IF\(n)"] {
            let keyword = n == 0 ? "if " : "elif "
            let expr = pyValue(cond)
            L.append(p + keyword + expr + ":")
            L += pyChain(b.body["DO\(n)"] ?? [], ind + 1, allowPass: true)
            n += 1
        }
        if let els = b.body["ELSE"], !els.isEmpty {
            L.append(p + "else:")
            L += pyChain(els, ind + 1, allowPass: true)
        }

    case "controls_repeat_ext":
        let times = pyValue(b.values["TIMES"])
        L.append(p + "for _ in range(int(\(times))):")
        L += pyChain(b.body["DO"] ?? [], ind + 1, allowPass: true)

    case "controls_whileUntil":
        let cond = (b.fields["MODE"] ?? "WHILE") == "UNTIL"
            ? "not (" + pyValue(b.values["BOOL"]) + ")"
            : pyValue(b.values["BOOL"])
        L.append(p + "while " + cond + ":")
        L += pyChain(b.body["DO"] ?? [], ind + 1, allowPass: true)

    case "controls_for":
        let loopVar = b.fields["VAR"] ?? "i"
        let from = pyValue(b.values["FROM"])
        let to = pyValue(b.values["TO"])
        let by = pyValue(b.values["BY"])
        L.append(p + "for \(loopVar) in range(int(\(from)), int(\(to)) + 1, int(\(by))):")
        L += pyChain(b.body["DO"] ?? [], ind + 1, allowPass: true)

    case "controls_flow_statements":
        L.append(p + ((b.fields["FLOW"] ?? "BREAK") == "CONTINUE" ? "continue" : "break"))

    case "variables_set":
        let name = b.fields["VAR"] ?? "item"
        let value = pyValue(b.values["VALUE"])
        L.append(p + "\(name) = \(value)")

    case "math_change":
        let v = b.fields["VAR"] ?? "item"
        let delta = pyValue(b.values["DELTA"])
        L.append(p + "\(v) = \(v) + \(delta)")

    default:
        L.append(p + "# " + b.type)
    }
    return L
}

func pyChain(_ list: [BNode], _ ind: Int, allowPass: Bool) -> [String] {
    var L: [String] = []
    for b in list { L += pyStatement(b, ind) }
    if L.isEmpty && allowPass { L.append(pyIndent(ind) + "pass") }
    return L
}

func genPython(program: [BNode], missionNameEN: String) -> [String] {
    var L = ["# DroneCode Lab - generated Python for djitellopy",
             "# " + (CURRENT_LANG == .th ? "ภารกิจ" : "mission") + ": " + missionNameEN,
             "from djitellopy import Tello",
             "import time, math, random",
             "",
             "tello = Tello()",
             "tello.connect()",
             "print(\"battery:\", tello.get_battery())",
             ""]
    if program.isEmpty {
        L.append("# " + (CURRENT_LANG == .th
                         ? "ยังไม่มีคำสั่งในบล็อก when program starts"
                         : "no blocks under \"when program starts\" yet"))
    } else {
        L += pyChain(program, 0, allowPass: false)
    }
    L.append("")
    L.append("tello.end()")
    return L
}
