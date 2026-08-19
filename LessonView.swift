import SwiftUI

enum LessonBlock: Identifiable {
    case heading(String)
    case paragraph(AttributedString)
    case list(ordered: Bool, items: [AttributedString])
    case note(AttributedString)

    var id: String {
        switch self {
        case .heading(let s): return "h" + s
        case .paragraph(let s): return "p" + String(s.characters)
        case .list(let o, let items): return "l\(o)" + items.map { String($0.characters) }.joined()
        case .note(let s): return "n" + String(s.characters)
        }
    }
}

private func unescape(_ s: String) -> String {
    s.replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&#39;", with: "'")
        .replacingOccurrences(of: "&amp;", with: "&")
}

private func inlineText(_ html: String) -> AttributedString {
    var s = html
    s = s.replacingOccurrences(of: "<code>", with: "`")
    s = s.replacingOccurrences(of: "</code>", with: "`")
    s = s.replacingOccurrences(of: "<b>", with: "**")
    s = s.replacingOccurrences(of: "</b>", with: "**")
    s = s.replacingOccurrences(of: "<br>", with: "\n")

    s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    s = unescape(s).trimmingCharacters(in: .whitespacesAndNewlines)
    if let a = try? AttributedString(markdown: s,
                                     options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
        return a
    }
    return AttributedString(s)
}

func parseLesson(_ html: String) -> [LessonBlock] {
    var blocks: [LessonBlock] = []
    let pattern = "<(h3|p|ol|ul|div)[^>]*>(.*?)</\\1>"
    guard let re = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
        return [.paragraph(inlineText(html))]
    }
    let ns = html as NSString
    for m in re.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
        let tag = ns.substring(with: m.range(at: 1))
        let inner = ns.substring(with: m.range(at: 2))
        switch tag {
        case "h3":
            blocks.append(.heading(String(inlineText(inner).characters)))
        case "p":
            blocks.append(.paragraph(inlineText(inner)))
        case "ol", "ul":
            var items: [AttributedString] = []
            if let li = try? NSRegularExpression(pattern: "<li>(.*?)</li>", options: [.dotMatchesLineSeparators]) {
                let ins = inner as NSString
                for lm in li.matches(in: inner, range: NSRange(location: 0, length: ins.length)) {
                    items.append(inlineText(ins.substring(with: lm.range(at: 1))))
                }
            }
            blocks.append(.list(ordered: tag == "ol", items: items))
        case "div":
            blocks.append(.note(inlineText(inner)))
        default:
            break
        }
    }
    return blocks
}

struct LessonPanel: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("", selection: $model.lessonTab) {
                    Text(t("tab.lesson")).tag(LessonTab.lesson)
                    Text(t("tab.reference")).tag(LessonTab.reference)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
                .fixedSize(horizontal: false, vertical: true)
                Spacer()
                BadgeView(key: model.badgeKey, style: model.badgeStyle)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            Divider()

            if model.lessonTab == .lesson {
                ScrollView { lessonBody.padding(18) }
                    .scrollIndicators(.hidden)
            } else {
                ScrollView { referenceBody.padding(18) }
                    .scrollIndicators(.hidden)
            }
        }
        .background(Color.white)
    }

    private var lessonBody: some View {
        VStack(alignment: .leading, spacing: 13) {
            ForEach(parseLesson(model.mission.brief)) { b in
                switch b {
                case .heading(let s):
                    Text(s).font(.system(size: 19, weight: .semibold))
                case .paragraph(let s):
                    Text(s).font(.system(size: 14)).foregroundStyle(Theme.text2)
                case .list(let ordered, let items):
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text(ordered ? "\(i + 1)." : "•")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.text3)
                                Text(item).font(.system(size: 14)).foregroundStyle(Theme.text2)
                            }
                        }
                    }
                case .note(let s):
                    Text(s)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.text2)
                        .padding(13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.bg2)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            HStack(spacing: 7) {
                chip(t("lesson.goal", [model.mission.goal]))
                if !model.mission.rings.isEmpty { chip(t("lesson.rings", [model.mission.rings.count])) }
                if !model.mission.obstacles.isEmpty { chip(t("lesson.obstacles", [model.mission.obstacles.count])) }
            }
            .padding(.top, 2)

            Text(t("lesson.tip"))
                .font(.system(size: 13))
                .foregroundStyle(Theme.text2)
                .padding(13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func chip(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 12))
            .foregroundStyle(Theme.text2)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 11).padding(.vertical, 5)
            .background(Theme.bg2)
            .clipShape(Capsule())
    }

    private var referenceBody: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            Text(t("ref.intro"))
                .font(.system(size: 13))
                .foregroundStyle(Theme.text2)
                .padding(13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.bottom, 6)

            ForEach(["ref.flight", "ref.move", "ref.turn", "ref.light", "ref.sense", "ref.logic"], id: \.self) { g in
                Text(t(g).uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .tracking(0.6)
                    .foregroundStyle(Theme.text3)
                    .padding(.top, 16).padding(.bottom, 2)
                ForEach(REFERENCE_ROWS.filter { $0.group == g }) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Circle().fill(row.color).frame(width: 8, height: 8)
                            Text(row.label).font(.system(size: 12.5, weight: .medium, design: .monospaced))
                    .lineLimit(1).fixedSize()
                        }
                        Text(row.desc).font(.system(size: 12.5)).foregroundStyle(Theme.text3)
                        HStack(spacing: 8) {
                            if !row.tello.isEmpty { codeChip(row.tello) }
                            if !row.python.isEmpty { codeChip(row.python) }
                        }
                    }
                    .padding(.vertical, 10)
                    Divider()
                }
            }
        }
    }

    private func codeChip(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11.5, design: .monospaced))
            .foregroundStyle(Theme.text2)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Theme.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

struct BadgeView: View {
    let key: String
    let style: String

    var body: some View {
        Text(t(key))
            .font(.system(size: 12, weight: .medium))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(fg)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(bg)
            .clipShape(Capsule())
    }

    private var bg: Color {
        switch style {
        case "pass": return Color(red: 0.906, green: 0.973, blue: 0.925)
        case "fail": return Color(red: 1.0, green: 0.925, blue: 0.918)
        default: return Theme.bg2
        }
    }

    private var fg: Color {
        switch style {
        case "pass": return Color(red: 0.118, green: 0.498, blue: 0.235)
        case "fail": return Color(red: 0.776, green: 0.137, blue: 0.090)
        default: return Theme.text2
        }
    }
}
