import SwiftUI

enum Theme {
    static let bg2 = Color(red: 0.961, green: 0.961, blue: 0.969)
    static let bg3 = Color(red: 0.980, green: 0.980, blue: 0.988)
    static let text = Color(red: 0.114, green: 0.114, blue: 0.122)
    static let text2 = Color(red: 0.431, green: 0.431, blue: 0.451)
    static let text3 = Color(red: 0.557, green: 0.557, blue: 0.576)
    static let accent = Color(red: 0.0, green: 0.443, blue: 0.890)
}

@main
@MainActor
struct DroneCodeLabApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .preferredColorScheme(.light)
                .tint(Theme.accent)
        }
    }
}

@MainActor
struct RootView: View {
    @EnvironmentObject var model: AppModel
    @StateObject private var arenaBox = ArenaBox()

    var body: some View {
        GeometryReader { geo in
            let mode = layoutMode(for: geo.size)
            ZStack(alignment: .bottom) {
                Theme.bg2.ignoresSafeArea()

                VStack(spacing: 0) {
                    if geo.size.height < 440 {
                        compactBar(mode: mode)
                    } else {
                        topBar(mode: mode)
                        controlBar
                    }
                    if mode == "tall" { portraitTabs }
                    layout(mode: mode)
                    if mode == "single" { tabBar }
                }
                .background(Theme.bg2)

                if mode == "split" && model.lessonSheetOpen {
                    Color.black.opacity(0.18)
                        .ignoresSafeArea()
                        .onTapGesture { model.lessonSheetOpen = false }
                    HStack {
                        LessonPanel()
                            .frame(width: min(380, geo.size.width * 0.86))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .black.opacity(0.22), radius: 30)
                            .padding(12)
                        Spacer()
                    }
                }

                if let toast = model.toast {
                    Text(toast.text)
                        .font(.system(size: 13.5))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .background(toastColor(toast.kind))
                        .clipShape(Capsule())
                        .padding(.bottom, mode == "single" ? 78 : 28)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeOut(duration: 0.2), value: model.toast?.text)
            .onAppear {
                model.arena = arenaBox.controller
                arenaBox.controller.rebuildMission(rings: model.mission.rings,
                                                   obstacles: model.mission.obstacles)
                arenaBox.controller.sync(model.sim)
                model.hudOpen = geo.size.width >= 1180
            }
        }
    }

    private func layoutMode(for size: CGSize) -> String {
        let w = size.width
        let h = size.height
        if w >= 1180 { return "wide" }
        if w >= 700 && h > w { return "tall" }
        if w >= 660 { return "split" }
        return "single"
    }

    private func toastColor(_ kind: String) -> Color {
        switch kind {
        case "good": return Color(red: 0.118, green: 0.353, blue: 0.196).opacity(0.94)
        case "bad": return Color(red: 0.471, green: 0.125, blue: 0.102).opacity(0.94)
        default: return Color(white: 0.12).opacity(0.94)
        }
    }

    private func compactBar(mode: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.text)
                    .frame(width: 22, height: 22)
                    .overlay(Image(systemName: "circle.grid.2x2")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white))

                missionMenu(compact: true)
                runButton(compact: true)
                controlButton(model.paused ? t("btn.resume") : t("btn.pause"),
                              icon: model.paused ? "play" : "pause",
                              enabled: model.running, compact: true) { model.togglePause() }
                controlButton(t("btn.stop"), icon: "stop", enabled: model.running,
                              tint: .red, compact: true) { model.onStop() }
                controlButton(t("btn.reset"), icon: "arrow.counterclockwise",
                              enabled: !model.running, compact: true) {
                    model.resetDrone(quiet: false)
                    model.setBadge("badge.notyet", "")
                }
                speedMenu(compact: true)

                if mode == "wide" || mode == "split" {
                    Button {
                        if mode == "wide" { model.lessonVisible.toggle() }
                        else { model.lessonSheetOpen.toggle() }
                    } label: {
                        Image(systemName: lessonShown(mode) ? "sidebar.left" : "sidebar.leading")
                            .font(.system(size: 15))
                            .foregroundStyle(lessonShown(mode) ? Theme.accent : Theme.text2)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                }

                Picker("", selection: $model.lang) {
                    Text("ไทย").tag(Lang.th)
                    Text("EN").tag(Lang.en)
                }
                .pickerStyle(.segmented)
                .frame(width: 92)

                Button {
                    toggleLandscape()
                } label: {
                    Image(systemName: model.landscapeOn ? "rectangle.portrait.rotate" : "rectangle.landscape.rotate")
                        .font(.system(size: 15))
                        .foregroundStyle(model.landscapeOn ? Theme.accent : Theme.text2)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .background(.thinMaterial)
    }

    private func topBar(mode: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Theme.text)
                .frame(width: 26, height: 26)
                .overlay(Image(systemName: "circle.grid.2x2")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white))
            Text("DroneCode Lab")
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .fixedSize()
            Spacer()

            if mode == "wide" || mode == "split" {
                Button {
                    if mode == "wide" { model.lessonVisible.toggle() }
                    else { model.lessonSheetOpen.toggle() }
                } label: {
                    Image(systemName: lessonShown(mode) ? "sidebar.left" : "sidebar.leading")
                        .font(.system(size: 17))
                        .foregroundStyle(lessonShown(mode) ? Theme.accent : Theme.text2)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .help(t(lessonShown(mode) ? "btn.lessonHide" : "btn.lesson"))
            }

            Picker("", selection: $model.lang) {
                Text("ไทย").tag(Lang.th)
                Text("EN").tag(Lang.en)
            }
            .pickerStyle(.segmented)
            .frame(width: 108)

            Button {
                toggleLandscape()
            } label: {
                Image(systemName: model.landscapeOn ? "rectangle.portrait.rotate" : "rectangle.landscape.rotate")
                    .font(.system(size: 16))
                    .foregroundStyle(model.landscapeOn ? Theme.accent : Theme.text2)
                    .frame(width: 34, height: 34)
                    .background(model.landscapeOn ? Theme.accent.opacity(0.12) : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(.thinMaterial)
    }

    private func missionMenu(compact: Bool = false) -> some View {
        Menu {
            ForEach(MISSIONS) { m in
                Button(m.name) {
                    UISound.controlTap.play()
                    model.applyMission(m.id)
                    model.logLine("log.mission", [m.name], kind: "sys")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(model.mission.name).lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold))
            }
            .fixedSize(horizontal: false, vertical: true)
            .font(.system(size: compact ? 13 : 14))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, compact ? 10 : 12).padding(.vertical, compact ? 6 : 8)
            .background(Theme.bg2)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .disabled(model.running)
    }

    private func runButton(compact: Bool = false) -> some View {
        Button {
            UISound.controlTap.play()
            Task { await model.onRun() }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "play.fill").font(.system(size: 12))
                Text(t("btn.run"))
            }
            .font(.system(size: compact ? 13 : 14, weight: .medium))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 13 : 16).padding(.vertical, compact ? 7 : 9)
            .background(Theme.accent)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(model.running)
        .opacity(model.running ? 0.4 : 1)
    }

    private func speedMenu(compact: Bool = false) -> some View {
        Menu {
            ForEach([0.5, 1.0, 2.0, 4.0], id: \.self) { r in
                Button(speedName(r)) { UISound.controlTap.play(); model.rate = r }
            }
        } label: {
            Text(speedName(model.rate))
                .font(.system(size: compact ? 13 : 14))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, compact ? 10 : 12).padding(.vertical, compact ? 6 : 8)
                .background(Theme.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
    }

    private var controlBar: some View {
        HStack(spacing: 10) {
            missionMenu()
            runButton()

            controlButton(model.paused ? t("btn.resume") : t("btn.pause"),
                          icon: model.paused ? "play" : "pause",
                          enabled: model.running) { model.togglePause() }

            controlButton(t("btn.stop"), icon: "stop", enabled: model.running, tint: .red) {
                model.onStop()
            }

            controlButton(t("btn.reset"), icon: "arrow.counterclockwise", enabled: !model.running) {
                model.resetDrone(quiet: false)
                model.setBadge("badge.notyet", "")
            }

            Spacer()

            Text(t("speed.label")).font(.system(size: 13)).foregroundStyle(Theme.text3)
                .lineLimit(1).fixedSize()
            speedMenu()
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(.thinMaterial)
    }

    private func speedName(_ r: Double) -> String {
        switch r {
        case 0.5: return t("speed.slow")
        case 2.0: return t("speed.fast")
        case 4.0: return t("speed.vfast")
        default: return t("speed.normal")
        }
    }

    private func controlButton(_ title: String, icon: String, enabled: Bool,
                               tint: Color = Theme.text2, compact: Bool = false,
                               action: @escaping () -> Void) -> some View {
        Button(action: { UISound.controlTap.play(); action() }) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12))
                Text(title)
            }
            .font(.system(size: compact ? 13 : 14, weight: .medium))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(enabled ? tint : Theme.text3.opacity(0.45))
            .padding(.horizontal, compact ? 11 : 14).padding(.vertical, compact ? 7 : 9)
            .background(Theme.bg2.opacity(enabled ? 1 : 0.5))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    @ViewBuilder
    private func layout(mode: String) -> some View {
        GeometryReader { g in
            let W = g.size.width
            let H = g.size.height
            switch mode {
            case "wide":
                let handles: CGFloat = model.lessonVisible ? 36 : 18
                let usable = max(320, W - handles)
                let lessonMax = Double(usable) * 0.42
                let lessonW = model.lessonVisible ? clamp(model.lessonWidth, 230, lessonMax) : 0
                let rest = usable - CGFloat(lessonW)
                let codeW = rest * CGFloat(clamp(model.codeFraction, 0.25, 0.75))
                HStack(spacing: 0) {
                    if model.lessonVisible {
                        LessonPanel().frame(width: CGFloat(lessonW)).modifier(PanelChrome())
                        SplitHandle(axis: .horizontal,
                                    value: model.lessonWidth,
                                    range: 230...max(231, lessonMax),
                                    perPoint: 1,
                                    onChange: { model.lessonWidth = $0 },
                                    onEnd: { arenaBox.controller.updateCamera(sim: model.sim, force: true) })
                    }
                    BlockEditorPanel().frame(width: codeW).modifier(PanelChrome())
                    SplitHandle(axis: .horizontal,
                                value: model.codeFraction,
                                range: 0.25...0.75,
                                perPoint: 1 / Double(max(1, rest)),
                                onChange: { model.codeFraction = $0 },
                                onEnd: { arenaBox.controller.updateCamera(sim: model.sim, force: true) })
                    ArenaPanel(arena: arenaBox.controller).modifier(PanelChrome())
                }
                .padding(.horizontal, 12).padding(.vertical, 12)

            case "tall":
                Group {
                    switch model.panelView {
                    case .lesson: LessonPanel().modifier(PanelChrome())
                    case .code: BlockEditorPanel().modifier(PanelChrome())
                    case .flight: ArenaPanel(arena: arenaBox.controller).modifier(PanelChrome())
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 12)
                .frame(width: W, height: H)

            case "split":
                let usable = max(320, W - 18)
                let codeW = usable * CGFloat(clamp(model.codeFraction, 0.25, 0.75))
                HStack(spacing: 0) {
                    BlockEditorPanel().frame(width: codeW).modifier(PanelChrome())
                    SplitHandle(axis: .horizontal,
                                value: model.codeFraction,
                                range: 0.25...0.75,
                                perPoint: 1 / Double(max(1, usable)),
                                onChange: { model.codeFraction = $0 },
                                onEnd: { arenaBox.controller.updateCamera(sim: model.sim, force: true) })
                    ArenaPanel(arena: arenaBox.controller).modifier(PanelChrome())
                }
                .padding(.horizontal, 12).padding(.vertical, 12)

            default:
                Group {
                    switch model.panelView {
                    case .lesson: LessonPanel().modifier(PanelChrome())
                    case .code: BlockEditorPanel().modifier(PanelChrome())
                    case .flight: ArenaPanel(arena: arenaBox.controller).modifier(PanelChrome())
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 10)
            }
        }
    }

    private var portraitTabs: some View {
        HStack(spacing: 6) {
            portraitTab(.lesson, "book", t("view.lesson"))
            portraitTab(.code, "chevron.left.forwardslash.chevron.right", t("view.code"))
            portraitTab(.flight, "cube", t("view.flight"))
        }
        .padding(4)
        .background(Color(white: 0.94))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 4)
    }

    private func portraitTab(_ v: PanelView, _ icon: String, _ title: String) -> some View {
        Button {
            UISound.navTap.play()
            model.panelView = v
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .medium))
                Text(title).font(.system(size: 13.5, weight: .medium)).lineLimit(1).fixedSize()
            }
            .foregroundStyle(model.panelView == v ? Theme.text : Theme.text2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(model.panelView == v ? Color.white : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .black.opacity(model.panelView == v ? 0.10 : 0), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var tabBar: some View {
        HStack {
            tabItem(.lesson, "book", t("view.lesson"))
            tabItem(.code, "chevron.left.forwardslash.chevron.right", t("view.code"))
            tabItem(.flight, "cube", t("view.flight"))
        }
        .padding(.top, 8).padding(.bottom, 6)
        .background(.thinMaterial)
    }

    private func tabItem(_ v: PanelView, _ icon: String, _ title: String) -> some View {
        Button {
            UISound.navTap.play()
            model.panelView = v
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 19))
                Text(title).font(.system(size: 11, weight: .medium)).lineLimit(1).fixedSize()
            }
            .foregroundStyle(model.panelView == v ? Theme.accent : Theme.text3)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func lessonShown(_ mode: String) -> Bool {
        mode == "wide" ? model.lessonVisible : model.lessonSheetOpen
    }

    private func toggleLandscape() {
        UISound.navTap.play()
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        if model.landscapeOn {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
            model.landscapeOn = false
            model.showToast(t("toast.landscapeOff"))
        } else {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { _ in }
            model.landscapeOn = true
            model.showToast(t("toast.landscapeOn"), "good")
        }
    }
}

struct PanelChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

@MainActor
final class ArenaBox: ObservableObject {
    let controller = ArenaController()
}
