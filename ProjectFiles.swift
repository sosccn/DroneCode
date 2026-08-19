import SwiftUI
import UniformTypeIdentifiers

struct BNodeDTO: Codable {
    var type: String
    var fields: [String: String]
    var nums: [String: Double]
    var values: [String: BNodeDTO]
    var body: [String: [BNodeDTO]]
}

struct ProjectFile: Codable {
    var mission: String
    var program: [BNodeDTO]
}

func toDTO(_ n: BNode) -> BNodeDTO {
    BNodeDTO(type: n.type,
             fields: n.fields,
             nums: n.nums,
             values: n.values.mapValues { toDTO($0) },
             body: n.body.mapValues { $0.map { toDTO($0) } })
}

func fromDTO(_ d: BNodeDTO) -> BNode {
    let n = BNode(d.type, fields: d.fields, nums: d.nums)
    for (k, v) in d.values { n.values[k] = fromDTO(v) }
    for (k, list) in d.body { n.body[k] = list.map { fromDTO($0) } }
    return n
}

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText, .json] }
    var text: String

    init(_ text: String = "") { self.text = text }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let s = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = s
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

@MainActor
extension AppModel {

    func projectJSON() -> String {
        let file = ProjectFile(mission: missionID, program: program.map { toDTO($0) })
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(file), let s = String(data: data, encoding: .utf8) {
            return s
        }
        return "{}"
    }

    func loadProject(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(ProjectFile.self, from: data)
            if MISSIONS.contains(where: { $0.id == file.mission }) {
                applyMission(file.mission)
            }
            program = file.program.map { fromDTO($0) }
            programVersion += 1
            showToast(t("toast.loaded"), "good")
        } catch {
            showToast(t("toast.loadErr", [error.localizedDescription]), "bad")
        }
    }

    func telloExportText() -> String {
        "# DroneCode Lab - Tello SDK 2.0\ncommand\n" + telloLines.joined(separator: "\n") + "\n"
    }

    func pythonExportText() -> String {
        genPython(program: program,
                  missionNameEN: MISSION_TEXT[missionID]?.name["en"] ?? "").joined(separator: "\n") + "\n"
    }
}
