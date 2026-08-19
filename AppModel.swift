import SwiftUI
import Combine

struct SimState {
    var x: Double = 0, y: Double = 0, z: Double = 0
    var yaw: Double = 0
    var speed: Double = 50
    var led: String = "off"
    var ledRGBv: [Int] = [0, 0, 0]
    var flying = false
    var battery: Double = 100
    var flightTime: Double = 0
    var pitch: Double = 0, roll: Double = 0
    var flipPitch: Double = 0, flipRoll: Double = 0
    var moving = false
    var statusKey: String = "status.ready"
}

struct LogLine: Identifiable {
    let id = UUID()
    let time: String
    let text: String
    let kind: String
}

enum ConsoleTab: String { case log, cmd, py }
enum LessonTab: String { case lesson, reference }
enum PanelView: String { case lesson, code, flight }
enum SheetState: String { case closed, peek, open }
enum CameraMode: String { case orbit, follow, fpv, top }

let CMD_LIMIT = 4000
let LOOP_LIMIT = 500
let PROC_DEPTH = 8

@MainActor
final class AppModel: ObservableObject {

    @Published var lang: Lang = .th {
        didSet { CURRENT_LANG = lang }
    }

    @Published var missionID: String = "basic"
    @Published var program: [BNode] = []
    @Published var programVersion = 0

    @Published var sim = SimState()
    @Published var flight = FlightLog()

    @Published var lines: [LogLine] = []
    @Published var telloLines: [String] = []
    @Published var consoleTab: ConsoleTab = .log

    @Published var running = false
    @Published var paused = false
    @Published var rate: Double = 1
    var abort = false
    var commands = 0
    var vars: [String: Double] = [:]
    var lastTrail = (x: 0.0, y: 0.0, z: 0.0)
    var lowWarned = false

    @Published var badgeKey = "badge.notyet"
    @Published var badgeStyle = ""
    @Published var warnedBlock: UUID?
    @Published var warnMessage = ""
    @Published var runningBlock: UUID?

    @Published var lessonTab: LessonTab = .lesson
    @Published var panelView: PanelView = .code
    @Published var sheetState: SheetState = .closed
    @Published var hudOpen = false
    @Published var lessonSheetOpen = false
    @Published var lessonVisible = true
    @Published var tallSplit: Double = 0.55
    @Published var lessonWidth: Double = 320
    @Published var codeFraction: Double = 0.5

    @Published var customRings: [RingSpec] = []
    @Published var customWalls: [Obstacle] = []
    @Published var selectedProp: Int?
    @Published var propEditorOpen = false
    @Published var cameraMode: CameraMode = .orbit
    @Published var landscapeOn = false
    @Published var toast: (text: String, kind: String)?

    weak var arena: ArenaController?

    var mission: Mission { findMission(missionID) }

    var activeRings: [RingSpec] { mission.rings + customRings }
    var activeObstacles: [Obstacle] { mission.obstacles + customWalls }
    var propCount: Int { customRings.count + customWalls.count }

    func propName(_ i: Int) -> String {
        if i < customRings.count { return t("props.ring") + " \(i + 1)" }
        return t("props.wall") + " \(i - customRings.count + 1)"
    }

    func addRing() {
        customRings.append(RingSpec(x: 0, y: 120, z: -150, rotY: 0))
        selectedProp = customRings.count - 1
        propEditorOpen = true
        refreshArena()
        logLine("log.propAdd", [t("props.ring")], kind: "sys")
    }

    func addWall() {
        customWalls.append(Obstacle(x: 0, z: -220, w: 200, d: 20, h: 150))
        selectedProp = customRings.count + customWalls.count - 1
        propEditorOpen = true
        refreshArena()
        logLine("log.propAdd", [t("props.wall")], kind: "sys")
    }

    func deleteProp(_ i: Int) {
        if i < customRings.count {
            customRings.remove(at: i)
        } else {
            let w = i - customRings.count
            if w < customWalls.count { customWalls.remove(at: w) }
        }
        selectedProp = propCount > 0 ? min(i, propCount - 1) : nil
        resetDrone(quiet: true)
        refreshArena()
    }

    func clearProps() {
        customRings = []
        customWalls = []
        selectedProp = nil
        propEditorOpen = false
        resetDrone(quiet: true)
        refreshArena()
        logLine("log.propClear", kind: "sys")
    }

    func nudgeProp(_ i: Int, dx: Double = 0, dz: Double = 0, dy: Double = 0,
                   drot: Double = 0, dw: Double = 0) {
        if i < customRings.count {
            var r = customRings[i]
            r.x = clamp(r.x + dx, -400, 400)
            r.z = clamp(r.z + dz, -400, 400)
            r.y = clamp(r.y + dy, 40, 400)
            r.rotY = (r.rotY + drot).truncatingRemainder(dividingBy: 360)
            customRings[i] = r
        } else {
            let w = i - customRings.count
            guard w < customWalls.count else { return }
            var o = customWalls[w]
            o.x = clamp(o.x + dx, -400, 400)
            o.z = clamp(o.z + dz, -400, 400)
            o.h = clamp(o.h + dy, 40, 400)
            o.w = clamp(o.w + dw, 40, 500)
            customWalls[w] = o
        }
        refreshArena()
    }

    func refreshArena() {
        arena?.rebuildMission(rings: activeRings, obstacles: activeObstacles)
        if flight.rings.count != activeRings.count {
            flight.rings = Array(repeating: false, count: activeRings.count)
        }
    }

    init() {
        CURRENT_LANG = lang
        flight.rings = Array(repeating: false, count: mission.rings.count)
        logLine("log.ready", kind: "sys")
    }

    func logLine(_ key: String, _ args: [CustomStringConvertible] = [], kind: String = "ok") {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        lines.append(LogLine(time: f.string(from: Date()), text: t(key, args), kind: kind))
        if lines.count > 400 { lines.removeFirst(lines.count - 400) }
    }

    func pushCmd(_ s: String) {
        telloLines.append(s)
        lines.append(LogLine(time: "", text: s, kind: "cmd"))
    }

    func showToast(_ text: String, _ kind: String = "") {
        toast = (text, kind)
        let mine = text
        Task {
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            if self.toast?.text == mine { self.toast = nil }
        }
    }

    func applyMission(_ id: String) {
        let hadProps = propCount > 0
        missionID = id
        badgeKey = "badge.notyet"
        badgeStyle = ""
        customRings = []
        customWalls = []
        selectedProp = nil
        propEditorOpen = false
        resetDrone(quiet: true)
        refreshArena()
        programVersion += 1
        if hadProps { showToast(t("toast.propMission")) }
    }

    func setBadge(_ key: String, _ style: String) {
        badgeKey = key
        badgeStyle = style
    }

    func resetDrone(quiet: Bool) {
        sim = SimState()
        flight = FlightLog()
        flight.rings = Array(repeating: false, count: activeRings.count)
        vars = [:]
        lowWarned = false
        lastTrail = (0, 0, 0)
        warnedBlock = nil
        warnMessage = ""
        runningBlock = nil
        arena?.clearTrail()
        arena?.resetRingVisual()
        arena?.sync(sim)
        if !quiet { logLine("log.reset", kind: "sys") }
    }

    func loadExample() {
        program = mission.example()
        programVersion += 1
        showToast(t("toast.example"), "")
    }

    func clearProgram() {
        program = []
        programVersion += 1
        showToast(t("toast.cleared"))
    }

    private var pyVersion = -1
    private var pyMission = ""
    private var pyLines: [String] = []

    func pythonLines() -> [String] {
        if pyVersion == programVersion && pyMission == missionID { return pyLines }
        pyLines = genPython(program: program, missionNameEN: MISSION_TEXT[missionID]?.name["en"] ?? "")
        pyVersion = programVersion
        pyMission = missionID
        return pyLines
    }

    var blockCount: Int {
        func count(_ list: [BNode]) -> Int {
            list.reduce(0) { acc, b in
                acc + 1 + b.body.values.reduce(0) { $0 + count($1) }
            }
        }
        return count(program) + 1
    }
}
