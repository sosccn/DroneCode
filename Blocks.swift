import SwiftUI

enum BColor {
    static let flight = Color(red: 0.204, green: 0.780, blue: 0.349)
    static let move   = Color(red: 0.000, green: 0.478, blue: 1.000)
    static let turn   = Color(red: 0.345, green: 0.337, blue: 0.839)
    static let light  = Color(red: 1.000, green: 0.584, blue: 0.000)
    static let sense  = Color(red: 0.188, green: 0.690, blue: 0.780)
    static let logic  = Color(red: 0.388, green: 0.388, blue: 0.400)
    static let loops  = Color(red: 0.686, green: 0.322, blue: 0.871)
    static let vars   = Color(red: 0.353, green: 0.784, blue: 0.980)
    static let start  = Color(red: 0.557, green: 0.557, blue: 0.576)
    static let danger = Color(red: 1.000, green: 0.231, blue: 0.188)
}

final class BNode: Identifiable, ObservableObject {
    let id = UUID()
    @Published var type: String

    @Published var fields: [String: String]

    @Published var nums: [String: Double]

    @Published var values: [String: BNode]

    @Published var body: [String: [BNode]]

    init(_ type: String,
         fields: [String: String] = [:],
         nums: [String: Double] = [:],
         values: [String: BNode] = [:],
         body: [String: [BNode]] = [:]) {
        self.type = type
        self.fields = fields
        self.nums = nums
        self.values = values
        self.body = body
    }

    func copyTree() -> BNode {
        let n = BNode(type, fields: fields, nums: nums)
        for (k, v) in values { n.values[k] = v.copyTree() }
        for (k, list) in body { n.body[k] = list.map { $0.copyTree() } }
        return n
    }

    var isContainer: Bool {
        ["controls_if", "controls_repeat_ext", "controls_whileUntil", "controls_for"].contains(type)
    }

    var color: Color {
        switch type {
        case "drone_takeoff", "drone_land", "drone_hover", "drone_stop", "drone_speed":
            return BColor.flight
        case "drone_emergency":
            return BColor.danger
        case "drone_move", "drone_move_by", "drone_goto", "drone_curve":
            return BColor.move
        case "drone_rotate", "drone_rotate_by", "drone_flip":
            return BColor.turn
        case "drone_led", "drone_led_rgb", "drone_print":
            return BColor.light
        case "drone_wait_until", "drone_get", "drone_is_flying", "drone_obstacle_ahead":
            return BColor.sense
        case "controls_repeat_ext", "controls_whileUntil", "controls_for", "controls_flow_statements":
            return BColor.loops
        case "controls_if", "logic_compare", "logic_operation", "logic_negate", "logic_boolean":
            return BColor.logic
        case "variables_set", "math_change", "variables_get":
            return BColor.vars
        default:
            return BColor.logic
        }
    }
}

func num(_ v: Double) -> BNode { BNode("math_number", nums: ["NUM": v]) }
func variableGet(_ name: String) -> BNode { BNode("variables_get", fields: ["VAR": name]) }
func sensorGet(_ name: String) -> BNode { BNode("drone_get", fields: ["SENSOR": name]) }
func obstacleAhead(_ cm: Double) -> BNode {
    BNode("drone_obstacle_ahead", values: ["DIST": num(cm)])
}
func arithmetic(_ a: BNode, _ op: String, _ b: BNode) -> BNode {
    BNode("math_arithmetic", fields: ["OP": op], values: ["A": a, "B": b])
}
func compare(_ a: BNode, _ op: String, _ b: BNode) -> BNode {
    BNode("logic_compare", fields: ["OP": op], values: ["A": a, "B": b])
}
func textNode(_ s: String) -> BNode { BNode("text", fields: ["TEXT": s]) }

struct PaletteItem: Identifiable {
    let id = UUID()
    let type: String
    let group: String
    let make: () -> BNode
}

struct PaletteGroup: Identifiable {
    let id = UUID()
    let titleKey: String
    let color: Color
    let items: [PaletteItem]
}

func makeBlock(_ type: String) -> BNode {
    switch type {
    case "drone_hover":       return BNode(type, nums: ["SEC": 0])
    case "drone_speed":       return BNode(type, nums: ["VALUE": 0])
    case "drone_move":        return BNode(type, fields: ["DIR": "forward"], nums: ["DIST": 0])
    case "drone_move_by":     return BNode(type, fields: ["DIR": "forward"], values: ["DISTANCE": num(0)])
    case "drone_goto":        return BNode(type, nums: ["X": 0, "Y": 0, "Z": 0, "SPEED": 0])
    case "drone_curve":       return BNode(type, nums: ["X1": 0, "Y1": 0, "Z1": 0,
                                                        "X2": 0, "Y2": 0, "Z2": 0, "SPEED": 0])
    case "drone_rotate":      return BNode(type, fields: ["WAY": "cw"], nums: ["DEG": 0])
    case "drone_rotate_by":   return BNode(type, fields: ["WAY": "cw"], values: ["DEGREES": num(0)])
    case "drone_flip":        return BNode(type, fields: ["WAY": "f"])
    case "drone_led":         return BNode(type, fields: ["COLOR": "red"])
    case "drone_led_rgb":     return BNode(type, values: ["R": num(0), "G": num(0), "B": num(0)])
    case "drone_print":       return BNode(type, values: ["TEXT": textNode("hello")])
    case "drone_wait_until":  return BNode(type, values: ["COND": obstacleAhead(100)])
    case "controls_if":       return BNode(type, values: ["IF0": obstacleAhead(80)], body: ["DO0": [], "ELSE": []])
    case "controls_repeat_ext": return BNode(type, values: ["TIMES": num(0)], body: ["DO": []])
    case "controls_whileUntil": return BNode(type, fields: ["MODE": "UNTIL"],
                                             values: ["BOOL": obstacleAhead(100)], body: ["DO": []])
    case "controls_for":      return BNode(type, fields: ["VAR": "i"],
                                           values: ["FROM": num(0), "TO": num(0), "BY": num(0)],
                                           body: ["DO": []])
    case "controls_flow_statements": return BNode(type, fields: ["FLOW": "BREAK"])
    case "variables_set":     return BNode(type, fields: ["VAR": "item"], values: ["VALUE": num(0)])
    case "math_change":       return BNode(type, fields: ["VAR": "item"], values: ["DELTA": num(0)])
    default:                  return BNode(type)
    }
}

private func paletteItems(_ group: String, _ types: [String]) -> [PaletteItem] {
    var list: [PaletteItem] = []
    for tp in types {
        list.append(PaletteItem(type: tp, group: group, make: { makeBlock(tp) }))
    }
    return list
}

private let paletteGroup_flight = PaletteGroup(
    titleKey: "ref.flight", color: BColor.flight,
    items: paletteItems("ref.flight", ["drone_takeoff", "drone_land", "drone_hover", "drone_stop", "drone_speed", "drone_emergency"]))

private let paletteGroup_move = PaletteGroup(
    titleKey: "ref.move", color: BColor.move,
    items: paletteItems("ref.move", ["drone_move", "drone_move_by", "drone_goto", "drone_curve"]))

private let paletteGroup_turn = PaletteGroup(
    titleKey: "ref.turn", color: BColor.turn,
    items: paletteItems("ref.turn", ["drone_rotate", "drone_rotate_by", "drone_flip"]))

private let paletteGroup_light = PaletteGroup(
    titleKey: "ref.light", color: BColor.light,
    items: paletteItems("ref.light", ["drone_led", "drone_led_rgb", "drone_print"]))

private let paletteGroup_sense = PaletteGroup(
    titleKey: "ref.sense", color: BColor.sense,
    items: paletteItems("ref.sense", ["drone_wait_until", "controls_if"]))

private let paletteGroup_logic = PaletteGroup(
    titleKey: "ref.logic", color: BColor.loops,
    items: paletteItems("ref.logic", ["controls_repeat_ext", "controls_whileUntil", "controls_for", "controls_flow_statements", "variables_set", "math_change"]))

let PALETTE: [PaletteGroup] = [
    paletteGroup_flight, paletteGroup_move, paletteGroup_turn, paletteGroup_light, paletteGroup_sense, paletteGroup_logic
]

func blockLabel(_ type: String) -> String {
    switch type {
    case "drone_start":       return "when program starts"
    case "drone_takeoff":     return "take off"
    case "drone_land":        return "land"
    case "drone_hover":       return "hover for %@ seconds"
    case "drone_stop":        return "stop and hover"
    case "drone_speed":       return "set speed to %@ cm/s"
    case "drone_emergency":   return "emergency stop"
    case "drone_move":        return "fly %@ %@ cm"
    case "drone_move_by":     return "fly %@ by"
    case "drone_goto":        return "go to x %@ y %@ z %@ speed %@"
    case "drone_curve":       return "fly curve via %@ %@ %@ to %@ %@ %@ speed %@"
    case "drone_rotate":      return "rotate %@ %@ degrees"
    case "drone_rotate_by":   return "rotate %@ by"
    case "drone_flip":        return "flip %@"
    case "drone_led":         return "set LED to %@"
    case "drone_led_rgb":     return "set LED red"
    case "drone_print":       return "print"
    case "drone_wait_until":  return "wait until"
    case "controls_if":       return "if"
    case "controls_repeat_ext": return "repeat"
    case "controls_whileUntil": return "repeat %@"
    case "controls_for":      return "count with %@"
    case "controls_flow_statements": return "%@ out of loop"
    case "variables_set":     return "set %@ to"
    case "math_change":       return "change %@ by"
    default:                  return type
    }
}

func paletteLabel(_ type: String) -> String {
    switch type {
    case "drone_hover":              return "hover for 0 seconds"
    case "drone_speed":              return "set speed to 0 cm/s"
    case "drone_move":               return "fly forward 0 cm"
    case "drone_move_by":            return "fly forward by 0"
    case "drone_goto":               return "go to x 0 y 0 z 0 speed 0"
    case "drone_curve":              return "curve via 0 0 0 to 0 0 0"
    case "drone_rotate":             return "rotate cw 0 degrees"
    case "drone_rotate_by":          return "rotate cw by 0"
    case "drone_flip":               return "flip f"
    case "drone_led":                return "set LED to red"
    case "drone_led_rgb":            return "set LED 0 0 0"
    case "controls_repeat_ext":      return "repeat 0 times"
    case "controls_whileUntil":      return "repeat until"
    case "controls_for":             return "count with i from 0 to 0 by 0"
    case "controls_flow_statements": return "break out of loop"
    case "variables_set":            return "set item to 0"
    case "math_change":              return "change item by 0"
    default:
        return blockLabel(type)
            .replacingOccurrences(of: "%@", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}

let DIR_OPTIONS = ["forward", "back", "left", "right", "up", "down"]
let WAY_OPTIONS = ["cw", "ccw"]
let FLIP_OPTIONS = ["f", "b", "l", "r"]
let LED_OPTIONS = ["off", "red", "green", "blue", "cyan", "yellow", "purple", "white", "orange", "pink"]
let SENSOR_OPTIONS = ["height", "battery", "time", "temp", "tof", "yaw", "pitch", "roll",
                      "speed", "pos_x", "pos_y", "pos_z", "dist_home", "front"]
let COMPARE_OPTIONS = ["EQ", "NEQ", "LT", "LTE", "GT", "GTE"]
let ARITH_OPTIONS = ["ADD", "MINUS", "MULTIPLY", "DIVIDE", "POWER"]

func compareSymbol(_ op: String) -> String {
    ["EQ": "=", "NEQ": "≠", "LT": "<", "LTE": "≤", "GT": ">", "GTE": "≥"][op] ?? "="
}

func arithSymbol(_ op: String) -> String {
    ["ADD": "+", "MINUS": "−", "MULTIPLY": "×", "DIVIDE": "÷", "POWER": "^"][op] ?? "+"
}

struct RefRow: Identifiable {
    let id = UUID()
    let label: String
    let tello: String
    let python: String
    let desc: String
    let color: Color
    let group: String
}

private let refRows1: [RefRow] = [
    RefRow(label: "take off", tello: "takeoff", python: "tello.takeoff()",
           desc: "Lift off and hover at about 1 m", color: BColor.flight, group: "ref.flight"),
    RefRow(label: "land", tello: "land", python: "tello.land()",
           desc: "Descend and land where the drone is", color: BColor.flight, group: "ref.flight"),
    RefRow(label: "hover for 2 seconds", tello: "delay 2", python: "time.sleep(2)",
           desc: "Stay in place for a number of seconds", color: BColor.flight, group: "ref.flight"),
    RefRow(label: "stop and hover", tello: "stop", python: "tello.send_control_command(\"stop\")",
           desc: "Cancel the current motion and hold position", color: BColor.flight, group: "ref.flight"),
    RefRow(label: "set speed to 50 cm/s", tello: "speed 50", python: "tello.set_speed(50)",
           desc: "Flight speed from 10 to 100 cm/s", color: BColor.flight, group: "ref.flight"),
    RefRow(label: "emergency stop", tello: "emergency", python: "tello.emergency()",
           desc: "Cut the motors at once, the drone drops", color: BColor.danger, group: "ref.flight"),
    RefRow(label: "fly forward 100 cm", tello: "forward 100", python: "tello.move_forward(100)",
           desc: "Move in one of six directions, 20 to 500 cm", color: BColor.move, group: "ref.move")
]

private let refRows2: [RefRow] = [
    RefRow(label: "fly forward by (value)", tello: "forward 50", python: "tello.move_forward(int(x))",
           desc: "Same move but the distance comes from a value block", color: BColor.move, group: "ref.move"),
    RefRow(label: "go to x y z speed", tello: "go 100 100 -100 60", python: "tello.go_xyz_speed(100, 100, -100, 60)",
           desc: "Fly straight to a point in the arena", color: BColor.move, group: "ref.move"),
    RefRow(label: "fly curve via a point", tello: "curve 80 120 -80 0 120 -160 60", python: "tello.curve_xyz_speed(...)",
           desc: "Arc through a middle point to the target", color: BColor.move, group: "ref.move"),
    RefRow(label: "rotate cw 90 degrees", tello: "cw 90", python: "tello.rotate_clockwise(90)",
           desc: "Yaw in place, 1 to 360 degrees", color: BColor.turn, group: "ref.turn"),
    RefRow(label: "rotate cw by (value)", tello: "cw 45", python: "tello.rotate_clockwise(int(x))",
           desc: "Same rotation with the angle from a value block", color: BColor.turn, group: "ref.turn"),
    RefRow(label: "flip forward", tello: "flip f", python: "tello.flip_forward()",
           desc: "Needs at least 80 cm of clearance", color: BColor.turn, group: "ref.turn"),
    RefRow(label: "set LED to red", tello: "EXT led 255 0 0", python: "tello.send_expansion_command(\"led 255 0 0\")",
           desc: "Ten preset colours on the expansion board", color: BColor.light, group: "ref.light")
]

private let refRows3: [RefRow] = [
    RefRow(label: "set LED red green blue", tello: "EXT led r g b", python: "tello.send_expansion_command(\"led %d %d %d\")",
           desc: "Any colour from three 0 to 255 values", color: BColor.light, group: "ref.light"),
    RefRow(label: "print", tello: "", python: "print(value)",
           desc: "Write a message into the console", color: BColor.light, group: "ref.light"),
    RefRow(label: "wait until", tello: "", python: "while not cond: time.sleep(0.1)",
           desc: "Hover until a condition becomes true", color: BColor.sense, group: "ref.sense"),
    RefRow(label: "get height", tello: "height?", python: "tello.get_height()",
           desc: "Read one of fourteen sensor values", color: BColor.sense, group: "ref.sense"),
    RefRow(label: "obstacle within 100 cm ahead", tello: "", python: "front_distance() < n",
           desc: "Forward range sensor as a true or false value", color: BColor.sense, group: "ref.sense"),
    RefRow(label: "if / else", tello: "", python: "if cond: ... else: ...",
           desc: "Run blocks only when a condition holds", color: BColor.logic, group: "ref.logic"),
    RefRow(label: "repeat 4 times", tello: "", python: "for _ in range(4):",
           desc: "Repeat the blocks inside a fixed number of times", color: BColor.loops, group: "ref.logic")
]

private let refRows4: [RefRow] = [
    RefRow(label: "repeat while / until", tello: "", python: "while cond:",
           desc: "Repeat as long as, or until, a condition holds", color: BColor.loops, group: "ref.logic"),
    RefRow(label: "count with i from 1 to 4 by 1", tello: "", python: "for i in range(1, 4 + 1, 1):",
           desc: "Counting loop that stores the round in a variable", color: BColor.loops, group: "ref.logic"),
    RefRow(label: "break out of loop", tello: "", python: "break / continue",
           desc: "Leave the loop or skip to the next round", color: BColor.loops, group: "ref.logic"),
    RefRow(label: "set item to / change item by", tello: "", python: "item = value",
           desc: "Store and update a value in a variable", color: BColor.vars, group: "ref.logic")
]

let REFERENCE_ROWS: [RefRow] = refRows1 + refRows2 + refRows3 + refRows4
