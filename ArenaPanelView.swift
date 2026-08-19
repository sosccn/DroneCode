import SwiftUI
import UniformTypeIdentifiers

struct ArenaPanel: View {
    @EnvironmentObject var model: AppModel
    let arena: ArenaController

    @GestureState private var dragOffset: CGFloat = 0
    @State private var orbitStart: CGPoint?
    @State private var zoomStart: Double?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            GeometryReader { geo in
                let sheetH = min(max(190, geo.size.height * 0.74), max(150, geo.size.height - 40))
                ZStack(alignment: .topLeading) {
                    ArenaView(controller: arena)
                        .gesture(
                            DragGesture(minimumDistance: 2)
                                .onChanged { g in
                                    let base: CGPoint
                                    if let s = orbitStart {
                                        base = s
                                    } else {
                                        base = CGPoint(x: arena.theta, y: arena.phi)
                                        orbitStart = base
                                    }
                                    arena.setOrbit(theta: Double(base.x) - Double(g.translation.width) * 0.006,
                                                   phi: Double(base.y) - Double(g.translation.height) * 0.005)
                                    arena.updateCamera(sim: model.sim, force: true)
                                }
                                .onEnded { _ in orbitStart = nil }
                        )
                        .simultaneousGesture(
                            MagnificationGesture(minimumScaleDelta: 0.005)
                                .onChanged { scale in
                                    let base = zoomStart ?? arena.radius
                                    if zoomStart == nil { zoomStart = base }
                                    arena.setRadius(base / Double(scale))
                                    arena.updateCamera(sim: model.sim, force: true)
                                }
                                .onEnded { _ in zoomStart = nil }
                        )

                    hudButton
                    if model.hudOpen { hudCard.padding(.top, 56).padding(.leading, 12) }

                    VStack(spacing: 8) {
                        zoomButton("plus.magnifyingglass") { arena.zoom(by: 1.25); arena.updateCamera(sim: model.sim, force: true) }
                        zoomButton("minus.magnifyingglass") { arena.zoom(by: 0.8); arena.updateCamera(sim: model.sim, force: true) }
                        zoomButton("scope") { arena.setRadius(6.4); arena.updateCamera(sim: model.sim, force: true) }
                    }
                    .padding(.top, 12).padding(.trailing, 12)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    VStack {
                        Spacer()
                        Text(t("view.hint"))
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.text3)
                            .padding(.trailing, 12).padding(.bottom, 54)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    if model.propEditorOpen, model.propCount > 0 {
                        VStack {
                            Spacer()
                            propEditor
                                .padding(.horizontal, 12)
                                .padding(.bottom, 54)
                        }
                    }

                    dataSheet(height: sheetH, container: geo.size.height)
                }
            }
        }
        .background(Color.white)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Label(t("panel.stage"), systemImage: "cube")
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .fixedSize()
            Spacer(minLength: 6)
            Menu {
                Button {
                    model.addRing()
                } label: {
                    Label(t("props.ring"), systemImage: "circle.circle")
                }
                Button {
                    model.addWall()
                } label: {
                    Label(t("props.wall"), systemImage: "rectangle.fill")
                }
                if model.propCount > 0 {
                    Divider()
                    Button {
                        model.propEditorOpen.toggle()
                    } label: {
                        Label(t("props.title"), systemImage: "slider.horizontal.3")
                    }
                    Button(role: .destructive) {
                        model.clearProps()
                    } label: {
                        Label(t("props.clear"), systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(model.propCount > 0 ? Theme.accent : Theme.text2)
                    .frame(width: 30, height: 30)
            }
            .disabled(model.running)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach([CameraMode.orbit, .follow, .fpv, .top], id: \.rawValue) { m in
                        Button {
                            UISound.cameraTap.play()
                            model.cameraMode = m
                            arena.camMode = m
                            arena.updateCamera(sim: model.sim, force: true)
                        } label: {
                            Text(t("cam." + m.rawValue))
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(model.cameraMode == m ? .white : Theme.text2)
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.horizontal, 11).padding(.vertical, 6)
                                .background(model.cameraMode == m ? Theme.text : Theme.bg2)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 2)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
    }

    private func zoomButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: { UISound.cameraTap.play(); action() }) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.text2)
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.86))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var hudButton: some View {
        Button {
            UISound.cameraTap.play()
            withAnimation(.easeOut(duration: 0.18)) { model.hudOpen.toggle() }
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(model.hudOpen ? Color.white : Theme.text2)
                .frame(width: 36, height: 36)
                .background(model.hudOpen ? Theme.text : Color.white.opacity(0.82))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.14), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
        .padding(12)
    }

    private var hudCard: some View {
        VStack(alignment: .leading, spacing: 3) {
            hudRow(t("hud.status"), t(model.sim.statusKey), accent: true)
            hudRow(t("hud.alt"), "\(Int(model.sim.y.rounded())) cm")
            hudRow(t("hud.yaw"), "\(Int(normDeg(model.sim.yaw).rounded())) deg")
            hudRow(t("hud.front"), model.activeObstacles.isEmpty
                   ? "--" : "\(Int(model.frontDistance().rounded())) cm")
            hudRow(t("hud.rings"), "\(model.flight.rings.filter { $0 }.count)/\(model.activeRings.count)")
        }
        .padding(.horizontal, 13).padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func hudRow(_ k: String, _ v: String, accent: Bool = false) -> some View {
        HStack {
            Text(k).font(.system(size: 12)).foregroundStyle(Theme.text3).lineLimit(1).fixedSize()
            Spacer(minLength: 18)
            Text(v)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(accent ? Theme.accent : Theme.text)
        }
        .frame(minWidth: 168)
    }

    private var propEditor: some View {
        let index = min(model.selectedProp ?? 0, max(0, model.propCount - 1))
        let isRing = index < model.customRings.count
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Menu {
                    ForEach(0..<model.propCount, id: \.self) { i in
                        Button(model.propName(i)) { model.selectedProp = i }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(model.propName(index))
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Theme.text)
                }
                Spacer()
                Button {
                    model.deleteProp(index)
                } label: {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                Button {
                    model.propEditorOpen = false
                } label: {
                    Image(systemName: "xmark").font(.system(size: 13)).foregroundStyle(Theme.text3)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                nudgePad(t("props.side"), minus: "arrow.left", plus: "arrow.right",
                         onMinus: { model.nudgeProp(index, dx: -10) },
                         onPlus: { model.nudgeProp(index, dx: 10) })
                nudgePad(t("props.depth"), minus: "arrow.down", plus: "arrow.up",
                         onMinus: { model.nudgeProp(index, dz: 10) },
                         onPlus: { model.nudgeProp(index, dz: -10) })
                nudgePad(t("props.height"), minus: "minus", plus: "plus",
                         onMinus: { model.nudgeProp(index, dy: -10) },
                         onPlus: { model.nudgeProp(index, dy: 10) })
                if isRing {
                    nudgePad(t("props.rot"), minus: "rotate.left", plus: "rotate.right",
                             onMinus: { model.nudgeProp(index, drot: -15) },
                             onPlus: { model.nudgeProp(index, drot: 15) })
                } else {
                    nudgePad(t("props.width"), minus: "minus", plus: "plus",
                             onMinus: { model.nudgeProp(index, dw: -20) },
                             onPlus: { model.nudgeProp(index, dw: 20) })
                }
            }

            Text(propInfo(index, isRing: isRing))
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(Theme.text3)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
    }

    private func propInfo(_ i: Int, isRing: Bool) -> String {
        if isRing, i < model.customRings.count {
            let r = model.customRings[i]
            return "x \(Int(r.x))  z \(Int(r.z))  y \(Int(r.y))  \(Int(r.rotY))°"
        }
        let w = i - model.customRings.count
        guard w < model.customWalls.count else { return "" }
        let o = model.customWalls[w]
        return "x \(Int(o.x))  z \(Int(o.z))  h \(Int(o.h))  w \(Int(o.w))"
    }

    private func nudgePad(_ title: String, minus: String, plus: String,
                          onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.system(size: 10)).foregroundStyle(Theme.text3).lineLimit(1).fixedSize()
            HStack(spacing: 4) {
                Button(action: onMinus) {
                    Image(systemName: minus)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 30, height: 26)
                        .background(Theme.bg2)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                Button(action: onPlus) {
                    Image(systemName: plus)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 30, height: 26)
                        .background(Theme.bg2)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func offset(for state: SheetState, height: CGFloat) -> CGFloat {
        switch state {
        case .open: return 0
        case .peek: return max(0, height - min(158, height * 0.75))
        case .closed: return max(0, height - 46)
        }
    }

    private func dataSheet(height: CGFloat, container: CGFloat) -> some View {
        let base = offset(for: model.sheetState, height: height)
        let y = min(max(0, base + dragOffset), offset(for: .closed, height: height))
        return VStack(spacing: 0) {
            handle(height: height)
            FlightSheetContent()
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 14, y: -6)
        .offset(y: container - height + y)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: model.sheetState)
    }

    private func handle(height: CGFloat) -> some View {
        VStack(spacing: 6) {
            Capsule().fill(Color(white: 0.82)).frame(width: 40, height: 5)
            HStack(spacing: 9) {
                Text(t("sheet.title"))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.text2)
                    .lineLimit(1)
                    .fixedSize()
                Text("\(Int(model.sim.y.rounded())) cm  \(Int(model.sim.battery.rounded()))%")
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundStyle(Theme.text3)
            }
        }
        .padding(.top, 8).padding(.bottom, 9)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { cycleSheet() }
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($dragOffset) { move, state, transaction in
                    transaction.disablesAnimations = true
                    state = move.translation.height
                }
                .onEnded { move in
                    snap(after: move.translation.height, height: height)
                }
        )
    }

    private func cycleSheet() {
        model.sheetState = model.sheetState == .closed ? .peek
            : (model.sheetState == .peek ? .open : .closed)
    }

    private func snap(after delta: CGFloat, height: CGFloat) {
        if abs(delta) < 6 { cycleSheet(); return }
        let states: [SheetState] = [.open, .peek, .closed]
        let current = offset(for: model.sheetState, height: height) + delta
        var best = states[0]
        var bestD = CGFloat.infinity
        for s in states {
            let d = abs(offset(for: s, height: height) - current)
            if d < bestD { bestD = d; best = s }
        }
        model.sheetState = best
    }
}

struct FlightSheetContent: View {
    @EnvironmentObject var model: AppModel
    @State private var showExportCmd = false
    @State private var showExportPy = false

    var body: some View {
        VStack(spacing: 0) {
            telemetry
            Divider()
            HStack {
                Picker("", selection: $model.consoleTab) {
                    Text(t("tab.log")).tag(ConsoleTab.log)
                    Text(t("tab.cmd")).tag(ConsoleTab.cmd)
                    Text(t("tab.py")).tag(ConsoleTab.py)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
                Spacer()
                MiniButton(title: t("btn.exportCmd")) {
                    if model.telloLines.isEmpty { model.showToast(t("toast.noCmd"), "bad") }
                    else { showExportCmd = true }
                }
                MiniButton(title: t("btn.exportPy")) { showExportPy = true }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .fileExporter(isPresented: $showExportCmd,
                          document: TextDocument(model.telloExportText()),
                          contentType: .plainText,
                          defaultFilename: "tello-commands") { result in
                if case .success = result { model.showToast(t("toast.exported"), "good") }
            }
            .fileExporter(isPresented: $showExportPy,
                          document: TextDocument(model.pythonExportText()),
                          contentType: .plainText,
                          defaultFilename: "dronecode-" + model.missionID) { result in
                if case .success = result { model.showToast(t("toast.exported"), "good") }
            }
            console
        }
    }

    private var telemetry: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                tele(t("tele.x"), "\(Int(model.sim.x.rounded()))")
                tele(t("tele.y"), "\(Int(model.sim.y.rounded()))")
                tele(t("tele.z"), "\(Int(model.sim.z.rounded()))")
                tele(t("tele.speed"), "\(Int(model.sim.speed.rounded()))")
                tele(t("tele.led"), model.sim.led)
                tele(t("tele.battery"), "\(Int(model.sim.battery.rounded()))%")
                tele(t("tele.time"), "\(Int(model.sim.flightTime.rounded()))s")
            }
            .padding(.horizontal, 12).padding(.top, 4).padding(.bottom, 10)
        }
    }

    private func tele(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(k).font(.system(size: 11)).foregroundStyle(Theme.text3).lineLimit(1).fixedSize()
            Text(v).font(.system(size: 14, design: .monospaced)).lineLimit(1).fixedSize()
        }
        .padding(.horizontal, 11).padding(.vertical, 6)
        .frame(minWidth: 76, alignment: .leading)
        .background(Theme.bg2)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var console: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    switch model.consoleTab {
                    case .log:
                        ForEach(model.lines) { line in
                            HStack(alignment: .top, spacing: 10) {
                                Text(line.time)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color(white: 0.78))
                                Text(line.text)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(colorFor(line.kind))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .id(line.id)
                        }
                    case .cmd:
                        if model.telloLines.isEmpty {
                            Text(t("toast.noCmd"))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Theme.text3)
                        } else {
                            ForEach(Array(model.telloLines.enumerated()), id: \.offset) { _, c in
                                Text(c)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(Theme.accent)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    case .py:
                        ForEach(Array(model.pythonLines().enumerated()), id: \.offset) { _, l in
                            Text(l)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(l.hasPrefix("#") ? Theme.text3 : Theme.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 14)
            }
            .onChange(of: model.lines.count) { _ in
                if model.consoleTab == .log, let last = model.lines.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private func colorFor(_ kind: String) -> Color {
        switch kind {
        case "cmd": return Theme.accent
        case "warn": return Color(red: 0.70, green: 0.31, blue: 0.0)
        case "err": return Color(red: 1.0, green: 0.23, blue: 0.19)
        case "sys": return Theme.text3
        default: return Theme.text2
        }
    }
}
