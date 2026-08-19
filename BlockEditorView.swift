import SwiftUI
import UniformTypeIdentifiers

struct DropSlot {
    let parent: BNode?
    let key: String
    let index: Int
}

@MainActor
final class EditorOps {
    static func insert(_ node: BNode, at key: SlotKey, model: AppModel) {
        var parent: BNode?
        if let pid = key.parentID {
            parent = find(id: pid, in: model.program)
            if parent == nil { return }
        }
        insert(node, into: DropSlot(parent: parent, key: key.key, index: key.index), model: model)
    }

    static func move(id: UUID, to key: SlotKey, model: AppModel) {
        guard let moving = find(id: id, in: model.program) else { return }
        if let pid = key.parentID {
            if pid == id { return }
            if contains(moving, id: pid) { return }
        }
        var target = key
        if key.parentID == nil, let current = model.program.firstIndex(where: { $0.id == id }) {
            if key.index == current || key.index == current + 1 { return }
            if key.index > current { target = SlotKey(parentID: nil, key: key.key, index: key.index - 1) }
        }
        guard let node = remove(id: id, model: model) else { return }
        insert(node, at: target, model: model)
    }

    static func insert(_ node: BNode, into slot: DropSlot, model: AppModel) {
        if let p = slot.parent {
            var list = p.body[slot.key] ?? []
            let i = min(max(0, slot.index), list.count)
            list.insert(node, at: i)
            p.body[slot.key] = list
        } else {
            let i = min(max(0, slot.index), model.program.count)
            model.program.insert(node, at: i)
        }
        model.programVersion += 1
    }

    @discardableResult
    static func remove(id: UUID, model: AppModel) -> BNode? {
        func walk(_ list: inout [BNode]) -> BNode? {
            for (i, b) in list.enumerated() {
                if b.id == id {
                    let n = list.remove(at: i)
                    return n
                }
                for key in Array(b.body.keys) {
                    var sub = b.body[key] ?? []
                    if let found = walk(&sub) {
                        b.body[key] = sub
                        return found
                    }
                    b.body[key] = sub
                }
            }
            return nil
        }
        var root = model.program
        let found = walk(&root)
        model.program = root
        model.programVersion += 1
        return found
    }

    static func contains(_ node: BNode, id: UUID) -> Bool {
        if node.id == id { return true }
        for (_, list) in node.body {
            for c in list where contains(c, id: id) { return true }
        }
        return false
    }

    static func find(id: UUID, in list: [BNode]) -> BNode? {
        for b in list {
            if b.id == id { return b }
            for (_, sub) in b.body {
                if let f = find(id: id, in: sub) { return f }
            }
        }
        return nil
    }
}

struct BlockEditorPanel: View {
    @EnvironmentObject var model: AppModel
    @StateObject private var drag = DragController()
    @Environment(\.verticalSizeClass) private var vClass
    @State private var paletteGroup = 0
    @State private var trayContentW: CGFloat = 0
    @State private var trayVisibleW: CGFloat = 0
    @State private var trayOffset: CGFloat = 0
    @State private var showSave = false
    @State private var showLoad = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            programArea
            Divider()
            palette
        }
        .background(Color.white)
        .environmentObject(drag)
        .coordinateSpace(name: EDITOR_SPACE)
        .onPreferenceChange(TrashFrameKey.self) { rect in
            drag.trashRect = rect
        }
        .onPreferenceChange(SlotFramesKey.self) { list in
            var table: [SlotKey: CGRect] = [:]
            for f in list { table[f.key] = f.rect }
            drag.frames = table
        }
        .overlay(alignment: .topLeading) { ghost }
    }

    @ViewBuilder
    private var ghost: some View {
        if let payload = drag.payload, let info = drag.label(for: payload, in: model.program) {
            DragGhost(text: info.0, color: info.1)
                .position(drag.point)
                .allowsHitTesting(false)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label(t("panel.editor"), systemImage: "chevron.left.forwardslash.chevron.right")
                .labelStyle(.titleAndIcon)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .fixedSize()
            Spacer(minLength: 6)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text(t("editor.blocks", [model.blockCount]))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.text2)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Theme.bg2).clipShape(Capsule())
                    MiniButton(title: t("editor.example")) { model.loadExample() }
                        .disabled(model.running)
                    MiniButton(title: t("editor.clear")) { model.clearProgram() }
                        .disabled(model.running)
                    MiniButton(title: t("editor.save")) { showSave = true }
                    MiniButton(title: t("editor.load")) { showLoad = true }
                        .disabled(model.running)
                }
                .padding(.trailing, 2)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .fileExporter(isPresented: $showSave,
                      document: TextDocument(model.projectJSON()),
                      contentType: .json,
                      defaultFilename: "dronecode-" + model.missionID) { result in
            if case .success = result { model.showToast(t("toast.saved"), "good") }
        }
        .fileImporter(isPresented: $showLoad, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result { model.loadProject(from: url) }
        }
    }

    private var tight: Bool { vClass == .compact }

    private var trashBar: some View {
        HStack(spacing: 9) {
            Image(systemName: drag.overTrash ? "trash.fill" : "trash")
                .font(.system(size: 16, weight: .medium))
            Text(t(drag.overTrash ? "editor.trashOver" : "editor.trash"))
                .font(.system(size: 13.5, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, drag.overTrash ? (tight ? 13 : 18) : (tight ? 9 : 13))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(drag.overTrash ? Color(red: 0.85, green: 0.16, blue: 0.12)
                                     : Color(red: 1.0, green: 0.31, blue: 0.26))
        )
        .overlay(
            GeometryReader { geo in
                Color.clear.preference(key: TrashFrameKey.self,
                                       value: geo.frame(in: .named(EDITOR_SPACE)))
            }
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .animation(.easeOut(duration: 0.14), value: drag.overTrash)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var programArea: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                startBlock
                SlotView(slot: DropSlot(parent: nil, key: "", index: 0))
                ForEach(Array(model.program.enumerated()), id: \.element.id) { i, b in
                    BlockRow(node: b)
                    SlotView(slot: DropSlot(parent: nil, key: "", index: i + 1))
                }
                if model.program.isEmpty {
                    Text(t("editor.dragHint"))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.text3)
                        .padding(.vertical, 18)
                }
                Color.clear.frame(height: 240)
            }
            .padding(16)
            .padding(.bottom, drag.movingBlock ? 68 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDisabled(drag.payload != nil)
        .background(Theme.bg3)
        .overlay(alignment: .bottom) {
            if drag.movingBlock { trashBar }
        }
    }

    private var startBlock: some View {
        Button {
            Task { await model.onRun() }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: model.running ? "hourglass" : "play.circle.fill")
                    .font(.system(size: 15))
                Text(blockLabel("drone_start"))
                    .font(.system(size: 13.5, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize()
                Text(t("editor.tapToRun"))
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                    .fixedSize()
            }
            .foregroundStyle(.white)
            .padding(.leading, 13).padding(.trailing, 16)
            .padding(.top, 11).padding(.bottom, 10)
            .background(StartShape().fill(model.running ? BColor.start.opacity(0.6) : BColor.start))
        }
        .buttonStyle(.plain)
        .disabled(model.running)
    }

    private var palette: some View {
        VStack(spacing: tight ? 5 : 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(PALETTE.enumerated()), id: \.element.id) { i, g in
                        Button {
                            paletteGroup = i
                            trayOffset = 0
                            trayContentW = 0
                        } label: {
                            Text(t(g.titleKey))
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(paletteGroup == i ? .white : Theme.text2)
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(paletteGroup == i ? g.color : Theme.bg2)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
            }

            GeometryReader { geo in
                HStack(spacing: 8) {
                    ForEach(PALETTE[paletteGroup].items) { item in
                        PaletteChip(type: item.type)
                    }
                }
                .background(
                    GeometryReader { inner in
                        Color.clear.preference(key: TrayWidthKey.self, value: inner.size.width)
                    }
                )
                .offset(x: -trayOffset)
                .frame(width: geo.size.width, alignment: .leading)
                .clipped()
                .onAppear { trayVisibleW = geo.size.width }
                .onChange(of: geo.size.width) { trayVisibleW = $0 }
            }
            .frame(height: tight ? 48 : 52)
            .padding(.horizontal, 14)
            .onPreferenceChange(TrayWidthKey.self) { trayContentW = $0 }

            if trayContentW > trayVisibleW + 1 {
                TraySlider(contentWidth: trayContentW,
                           visibleWidth: trayVisibleW,
                           offset: $trayOffset)
                    .padding(.horizontal, 14)
            } else if !tight {
                Text(t("editor.dragTip"))
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.text3)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, tight ? 6 : 10)
        .background(Color.white)
    }
}

struct PaletteChip: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var drag: DragController
    let type: String

    var body: some View {
        let sample = makeBlock(type)
        let title = paletteLabel(type)
        return Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .lineLimit(1)
            .fixedSize()
            .padding(.leading, 12).padding(.trailing, 13)
            .padding(.top, 9).padding(.bottom, 8)
            .background(BlockShape().fill(sample.color))
            .padding(.bottom, NOTCH_D)
            .opacity(dragging ? 0.35 : 1)
            .scaleEffect(dragging ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: dragging)
            .blockDrag(.newBlock(type), enabled: !model.running) {
                if let slot = drag.target {
                    EditorOps.insert(makeBlock(type), at: slot, model: model)
                }
            }
    }

    private var dragging: Bool {
        drag.payload == .newBlock(type)
    }
}

struct SlotView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var drag: DragController
    let slot: DropSlot
    @State private var targeted = false

    private var key: SlotKey {
        SlotKey(parentID: slot.parent?.id, key: slot.key, index: slot.index)
    }

    private var active: Bool {
        drag.payload != nil && drag.target == key
    }

    private var open: Bool { active || targeted }

    var body: some View {
        ZStack(alignment: .leading) {
            Color.clear
            if open {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.accent)
                    .frame(width: 132, height: 6)
                    .padding(.leading, 2)
            }
        }
        .frame(height: open ? 24 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: SlotFramesKey.self,
                        value: [SlotFrame(key: key, rect: geo.frame(in: .named(EDITOR_SPACE)))])
                }
            )
            .animation(.easeOut(duration: 0.12), value: active)
            .dropDestination(for: String.self) { items, _ in
                guard let payload = items.first else { return false }
                return handle(payload)
            } isTargeted: { targeted = $0 }
    }

    private func handle(_ payload: String) -> Bool {
        if payload.hasPrefix("new:") {
            let type = String(payload.dropFirst(4))
            EditorOps.insert(makeBlock(type), into: slot, model: model)
            return true
        }
        if payload.hasPrefix("move:"), let id = UUID(uuidString: String(payload.dropFirst(5))) {
            EditorOps.move(id: id, to: key, model: model)
            return true
        }
        return false
    }
}

struct BlockRow: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var drag: DragController
    @ObservedObject var node: BNode

    private var grip: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.8))
            .frame(width: 26, height: 32)
            .contentShape(Rectangle())
            .blockDrag(.moveBlock(node.id), enabled: !model.running) {
                if drag.overTrash {
                    EditorOps.remove(id: node.id, model: model)
                    model.showToast(t("toast.blockDeleted"))
                } else if let slot = drag.target {
                    EditorOps.move(id: node.id, to: slot, model: model)
                }
            }
    }

    var body: some View {
        if node.isContainer { container } else { head }
    }

    private var bodyKeys: [String] {
        node.type == "controls_if" ? ["DO0", "ELSE"] : ["DO"]
    }

    private var container: some View {
        VStack(alignment: .leading, spacing: 0) {
            head
            ForEach(bodyKeys, id: \.self) { key in
                if key == "ELSE" { elseBar }
                HStack(alignment: .top, spacing: 0) {
                    Rectangle()
                        .fill(node.color)
                        .frame(width: RAIL_W)
                    VStack(alignment: .leading, spacing: 0) {
                        SlotView(slot: DropSlot(parent: node, key: key, index: 0))
                        ForEach(Array((node.body[key] ?? []).enumerated()), id: \.element.id) { i, child in
                            BlockRow(node: child)
                            SlotView(slot: DropSlot(parent: node, key: key, index: i + 1))
                        }
                    }
                    .padding(.leading, 4)
                    .padding(.vertical, 5)
                    .frame(minHeight: 26, alignment: .topLeading)
                }
            }
            FootShape()
                .fill(node.color)
                .frame(width: 104, height: 13)
        }
        .opacity(drag.payload == .moveBlock(node.id) ? 0.35 : 1)
    }

    private var elseBar: some View {
        HStack(spacing: 0) {
            Text("else")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .fixedSize()
                .padding(.leading, 14)
                .padding(.vertical, 6)
            Spacer(minLength: 0)
        }
        .frame(width: 118, alignment: .leading)
        .background(node.color)
    }

    private var head: some View {
        HStack(spacing: 7) {
            grip
            BlockContent(node: node)
            if model.warnedBlock == node.id {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.leading, 6).padding(.trailing, 12)
        .padding(.top, node.isContainer ? 7 : 8)
        .padding(.bottom, 8)
        .background(
            BlockShape(topNotch: true, bottomTab: !node.isContainer)
                .fill(node.color)
        )
        .overlay(
            BlockShape(topNotch: true, bottomTab: !node.isContainer)
                .stroke(Color.white, lineWidth: model.runningBlock == node.id ? 2.5 : 0)
        )
        .opacity(node.isContainer ? 1 : (drag.payload == .moveBlock(node.id) ? 0.35 : 1))
        .contextMenu {
            Button(role: .destructive) {
                EditorOps.remove(id: node.id, model: model)
            } label: {
                Label(t("editor.delete"), systemImage: "trash")
            }
        }
    }
}

struct BlockContent: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var node: BNode
    @State private var editing: String?

    var body: some View {
        HStack(spacing: 6) {
            content
        }
        .foregroundStyle(.white)
        .sheet(item: Binding(get: { editing.map { EditKey(key: $0) } },
                             set: { editing = $0?.key })) { item in
            NumberEditor(title: item.key,
                         initial: node.nums[item.key] ?? 0,
                         unit: unitOf(item.key)) { newValue in
                node.nums[item.key] = newValue
                model.programVersion += 1
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch node.type {
        case "drone_hover", "drone_speed":
            flightFields
        case "drone_move", "drone_move_by", "drone_goto", "drone_curve":
            moveFields
        case "drone_rotate", "drone_rotate_by", "drone_flip":
            turnFields
        case "drone_led", "drone_led_rgb", "drone_print", "drone_wait_until":
            outputFields
        case "controls_if", "controls_repeat_ext", "controls_whileUntil", "controls_for",
             "controls_flow_statements", "variables_set", "math_change":
            logicFields
        default:
            label(blockLabel(node.type))
        }
    }

    @ViewBuilder
    private var flightFields: some View {
        switch node.type {
        case "drone_hover":
            label("hover for"); numField("SEC"); label("seconds")
        case "drone_speed":
            label("set speed to"); numField("VALUE"); label("cm/s")
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var moveFields: some View {
        switch node.type {
        case "drone_move":
            label("fly"); menuField("DIR", DIR_OPTIONS); numField("DIST"); label("cm")
        case "drone_move_by":
            label("fly"); menuField("DIR", DIR_OPTIONS); label("by"); valueField("DISTANCE")
        case "drone_goto":
            label("go to x"); numField("X"); label("y"); numField("Y")
            label("z"); numField("Z"); label("speed"); numField("SPEED")
        case "drone_curve":
            label("curve via"); numField("X1"); numField("Y1"); numField("Z1")
            label("to"); numField("X2"); numField("Y2"); numField("Z2")
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var turnFields: some View {
        switch node.type {
        case "drone_rotate":
            label("rotate"); menuField("WAY", WAY_OPTIONS); numField("DEG"); label("degrees")
        case "drone_rotate_by":
            label("rotate"); menuField("WAY", WAY_OPTIONS); label("by"); valueField("DEGREES")
        case "drone_flip":
            label("flip"); menuField("WAY", FLIP_OPTIONS)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var outputFields: some View {
        switch node.type {
        case "drone_led":
            label("set LED to"); menuField("COLOR", LED_OPTIONS)
        case "drone_led_rgb":
            label("set LED"); valueField("R"); valueField("G"); valueField("B")
        case "drone_print":
            label("print"); valueField("TEXT")
        case "drone_wait_until":
            label("wait until"); valueField("COND")
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var logicFields: some View {
        switch node.type {
        case "controls_if":
            label("if"); valueField("IF0")
        case "controls_repeat_ext":
            label("repeat"); valueField("TIMES"); label("times")
        case "controls_whileUntil":
            label("repeat"); menuField("MODE", ["WHILE", "UNTIL"]); valueField("BOOL")
        case "controls_for":
            label("count with"); varField(); label("from"); valueField("FROM")
            label("to"); valueField("TO"); label("by"); valueField("BY")
        case "controls_flow_statements":
            menuField("FLOW", ["BREAK", "CONTINUE"]); label("out of loop")
        case "variables_set":
            label("set"); varField(); label("to"); valueField("VALUE")
        case "math_change":
            label("change"); varField(); label("by"); valueField("DELTA")
        default:
            EmptyView()
        }
    }

    private struct EditKey: Identifiable { let key: String; var id: String { key } }

    private func label(_ s: String) -> some View {
        Text(s).font(.system(size: 13.5, weight: .medium)).lineLimit(1).fixedSize()
    }

    private func numField(_ key: String) -> some View {
        Button {
            editing = key
        } label: {
            Text(fmtNum(node.nums[key] ?? 0))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(node.color)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Color.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(model.running)
    }

    private func unitOf(_ key: String) -> String {
        switch key {
        case "SEC": return "s"
        case "DEG": return "deg"
        case "VALUE", "SPEED": return "cm/s"
        default: return "cm"
        }
    }

    private func menuField(_ key: String, _ options: [String]) -> some View {
        Menu {
            ForEach(options, id: \.self) { o in
                Button(o) {
                    node.fields[key] = o
                    model.programVersion += 1
                }
            }
        } label: {
            Text(node.fields[key] ?? options.first ?? "")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(node.color)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Color.white)
                .clipShape(Capsule())
        }
        .disabled(model.running)
    }

    private func varField() -> some View {
        Menu {
            ForEach(["i", "n", "item", "count", "step"], id: \.self) { v in
                Button(v) {
                    node.fields["VAR"] = v
                    model.programVersion += 1
                }
            }
        } label: {
            Text(node.fields["VAR"] ?? "i")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(node.color)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Color.white)
                .clipShape(Capsule())
        }
        .disabled(model.running)
    }

    private func valueField(_ key: String) -> some View {
        ExpressionChip(owner: node, key: key)
    }
}

struct NumberEditor: View {
    let title: String
    let initial: Double
    let unit: String
    let onCommit: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        VStack(spacing: 16) {
            Text(title + (unit.isEmpty ? "" : " (" + unit + ")"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.text)

            HStack(spacing: 14) {
                Button { bump(-step) } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)

                TextField("0", text: $text)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.text)
                    .tint(Theme.accent)
                    .frame(width: 140)
                    .padding(.vertical, 8)
                    .background(Theme.bg2)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button { bump(step) } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { p in
                    Button {
                        text = fmtNum(p)
                    } label: {
                        Text(fmtNum(p))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.text)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Theme.bg2)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                onCommit(Double(text.trimmingCharacters(in: .whitespaces)) ?? initial)
                dismiss()
            } label: {
                Text(t("editor.done"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30).padding(.vertical, 10)
                    .background(Theme.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear { text = fmtNum(initial) }
        .presentationDetents([.height(290)])
    }

    private func bump(_ d: Double) {
        let v = (Double(text.trimmingCharacters(in: .whitespaces)) ?? initial) + d
        text = fmtNum(v)
    }

    private var step: Double {
        switch title {
        case "SEC", "BY", "FROM", "TO": return 1
        case "DEG": return 15
        default: return 10
        }
    }

    private var presets: [Double] {
        switch title {
        case "SEC": return [1, 2, 3, 5]
        case "DEG": return [45, 90, 180, 270]
        case "VALUE", "SPEED": return [20, 50, 80, 100]
        case "FROM", "BY": return [1, 2, 5, 10]
        case "TO": return [4, 6, 8, 10]
        default: return [20, 50, 100, 200]
        }
    }
}

struct ExpressionChip: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var owner: BNode
    let key: String
    @State private var editing = false
    @State private var draft = num(0)

    var body: some View {
        Button {
            draft = (owner.values[key] ?? num(0)).copyTree()
            editing = true
        } label: {
            Text(describe(owner.values[key]))
                .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                .foregroundStyle(owner.color)
                .lineLimit(1)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Color.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(model.running)
        .sheet(isPresented: $editing) {
            NavigationStack {
                ExpressionEditor(node: draft, depth: 0, onReplace: { draft = $0 })
                    .navigationTitle(t("editor.value"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(t("editor.cancel")) { editing = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(t("editor.done")) {
                                owner.values[key] = draft
                                model.programVersion += 1
                                editing = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

func describe(_ b: BNode?) -> String {
    guard let b = b else { return "0" }
    switch b.type {
    case "math_number":
        return fmtNum(b.nums["NUM"] ?? 0)
    case "variables_get":
        return b.fields["VAR"] ?? "i"
    case "drone_get":
        let sensor = b.fields["SENSOR"] ?? "height"
        return sensor + "?"
    case "drone_is_flying":
        return "is flying"
    case "drone_obstacle_ahead":
        let limit = describe(b.values["DIST"])
        return "obstacle < " + limit + " cm"
    case "logic_compare":
        let a = describe(b.values["A"])
        let op = compareSymbol(b.fields["OP"] ?? "EQ")
        let c = describe(b.values["B"])
        return [a, op, c].joined(separator: " ")
    case "math_arithmetic":
        let a = describe(b.values["A"])
        let op = arithSymbol(b.fields["OP"] ?? "ADD")
        let c = describe(b.values["B"])
        return [a, op, c].joined(separator: " ")
    case "logic_operation":
        let a = describe(b.values["A"])
        let op = (b.fields["OP"] ?? "AND") == "AND" ? "and" : "or"
        let c = describe(b.values["B"])
        return [a, op, c].joined(separator: " ")
    case "logic_negate":
        let inner = describe(b.values["BOOL"])
        return "not (" + inner + ")"
    case "logic_boolean":
        return (b.fields["BOOL"] ?? "TRUE") == "TRUE" ? "true" : "false"
    case "text":
        let value = b.fields["TEXT"] ?? ""
        return "\"" + value + "\""
    default:
        return b.type
    }
}

struct ExpressionEditor: View {

    @ObservedObject var node: BNode
    let depth: Int
    let onReplace: (BNode) -> Void

    private let kinds = ["math_number", "variables_get", "drone_get",
                         "drone_obstacle_ahead", "logic_compare", "math_arithmetic",
                         "logic_operation", "logic_negate", "logic_boolean",
                         "drone_is_flying", "text"]

    var body: some View {
        Form {
            Section(t("editor.kind")) {
                Picker(t("editor.kind"), selection: Binding(
                    get: { node.type },
                    set: { onReplace(defaultNode(for: $0)) })) {
                    ForEach(kinds, id: \.self) { k in Text(kindName(k)).tag(k) }
                }
                .pickerStyle(.menu)
            }

            switch node.type {
            case "math_number":
                Section(t("editor.value")) {
                    stepperRow(get: { node.nums["NUM"] ?? 0 }, set: { node.nums["NUM"] = $0 }, step: 10)
                    presetRow([20, 50, 100, 150, 200]) { node.nums["NUM"] = $0 }
                }
            case "variables_get":
                Section(t("editor.variable")) {
                    Picker("", selection: Binding(
                        get: { node.fields["VAR"] ?? "i" },
                        set: { node.fields["VAR"] = $0 })) {
                        ForEach(["i", "n", "item", "count", "step"], id: \.self) { Text($0).tag($0) }
                    }
                }
            case "drone_get":
                Section(t("editor.sensor")) {
                    Picker("", selection: Binding(
                        get: { node.fields["SENSOR"] ?? "height" },
                        set: { node.fields["SENSOR"] = $0 })) {
                        ForEach(SENSOR_OPTIONS, id: \.self) { Text($0).tag($0) }
                    }
                }
            case "drone_obstacle_ahead":
                Section("cm") {
                    stepperRow(get: { node.values["DIST"]?.nums["NUM"] ?? 100 },
                               set: { node.values["DIST"] = num($0) }, step: 10)
                    presetRow([50, 80, 100, 150]) { node.values["DIST"] = num($0) }
                }
            case "text":
                Section(t("editor.value")) {
                    TextField("", text: Binding(
                        get: { node.fields["TEXT"] ?? "" },
                        set: { node.fields["TEXT"] = $0 }))
                }
            case "logic_boolean":
                Section(t("editor.value")) {
                    Picker("", selection: Binding(
                        get: { node.fields["BOOL"] ?? "TRUE" },
                        set: { node.fields["BOOL"] = $0 })) {
                        Text("true").tag("TRUE")
                        Text("false").tag("FALSE")
                    }
                    .pickerStyle(.segmented)
                }
            case "logic_negate":
                if depth < 2, let inner = node.values["BOOL"] {
                    Section("not") {
                        AnyView(ExpressionEditor(node: inner, depth: depth + 1,
                                                 onReplace: { node.values["BOOL"] = $0 }))
                    }
                }
            case "logic_operation":
                Section(t("editor.operator")) {
                    Picker("", selection: Binding(
                        get: { node.fields["OP"] ?? "AND" },
                        set: { node.fields["OP"] = $0 })) {
                        Text("and").tag("AND")
                        Text("or").tag("OR")
                    }
                    .pickerStyle(.segmented)
                }
                subSections()
            case "logic_compare", "math_arithmetic":
                Section(t("editor.operator")) {
                    Picker("", selection: Binding(
                        get: { node.fields["OP"] ?? (node.type == "logic_compare" ? "EQ" : "ADD") },
                        set: { node.fields["OP"] = $0 })) {
                        ForEach(node.type == "logic_compare" ? COMPARE_OPTIONS : ARITH_OPTIONS, id: \.self) { o in
                            Text(node.type == "logic_compare" ? compareSymbol(o) : arithSymbol(o)).tag(o)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                subSections()
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func subSections() -> some View {
        if depth < 2 {
            if let a = node.values["A"] {
                Section("A") {
                    AnyView(ExpressionEditor(node: a, depth: depth + 1,
                                             onReplace: { node.values["A"] = $0 }))
                }
            }
            if let b = node.values["B"] {
                Section("B") {
                    AnyView(ExpressionEditor(node: b, depth: depth + 1,
                                             onReplace: { node.values["B"] = $0 }))
                }
            }
        }
    }

    private func stepperRow(get: @escaping () -> Double, set: @escaping (Double) -> Void,
                            step: Double) -> some View {
        HStack {
            Button { set(get() - step) } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
            Spacer()
            Text(fmtNum(get()))
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.text)
            Spacer()
            Button { set(get() + step) } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
        }
    }

    private func presetRow(_ values: [Double], _ apply: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(values, id: \.self) { p in
                Button { apply(p) } label: {
                    Text(fmtNum(p))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.bg2)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func kindName(_ k: String) -> String {
        switch k {
        case "math_number": return "number"
        case "variables_get": return "variable"
        case "drone_get": return "sensor"
        case "drone_obstacle_ahead": return "obstacle ahead"
        case "logic_operation": return "and / or"
        case "logic_negate": return "not"
        case "logic_boolean": return "true / false"
        case "logic_compare": return "compare"
        case "math_arithmetic": return "arithmetic"
        case "drone_is_flying": return "is flying"
        case "text": return "text"
        default: return k
        }
    }

    private func defaultNode(for kind: String) -> BNode {
        switch kind {
        case "math_number": return num(0)
        case "variables_get": return variableGet("i")
        case "drone_get": return sensorGet("height")
        case "drone_obstacle_ahead": return obstacleAhead(100)
        case "logic_compare": return compare(sensorGet("height"), "GT", num(100))
        case "math_arithmetic": return arithmetic(variableGet("i"), "MULTIPLY", num(20))
        case "logic_operation":
            return BNode("logic_operation", fields: ["OP": "AND"],
                         values: ["A": obstacleAhead(100),
                                  "B": compare(sensorGet("height"), "GT", num(100))])
        case "logic_negate":
            return BNode("logic_negate", values: ["BOOL": obstacleAhead(100)])
        case "logic_boolean":
            return BNode("logic_boolean", fields: ["BOOL": "TRUE"])
        case "drone_is_flying": return BNode("drone_is_flying")
        case "text": return textNode("hello")
        default: return num(0)
        }
    }
}

struct MiniButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.text2)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 11).padding(.vertical, 6)
                .background(Theme.bg2)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
