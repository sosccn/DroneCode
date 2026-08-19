import SwiftUI
import UIKit

let EDITOR_SPACE = "editor"

struct SlotKey: Hashable {
    let parentID: UUID?
    let key: String
    let index: Int
}

struct SlotFrame: Equatable {
    let key: SlotKey
    let rect: CGRect
}

struct TrashFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

struct SlotFramesKey: PreferenceKey {
    static var defaultValue: [SlotFrame] = []
    static func reduce(value: inout [SlotFrame], nextValue: () -> [SlotFrame]) {
        value.append(contentsOf: nextValue())
    }
}

enum DragPayload: Equatable {
    case newBlock(String)
    case moveBlock(UUID)
}

@MainActor
final class DragController: ObservableObject {
    @Published var payload: DragPayload?
    @Published var point: CGPoint = .zero
    @Published var target: SlotKey?
    @Published var overTrash = false

    var frames: [SlotKey: CGRect] = [:]
    var trashRect: CGRect = .zero

    var movingBlock: Bool {
        if case .moveBlock = payload { return true }
        return false
    }

    func begin(_ p: DragPayload, at point: CGPoint) {
        payload = p
        self.point = point
        updateTarget()
    }

    func move(to point: CGPoint) {
        self.point = point
        updateTarget()
    }

    func cancel() {
        payload = nil
        target = nil
        overTrash = false
    }

    private func updateTarget() {
        if movingBlock, trashRect != .zero, trashRect.insetBy(dx: -12, dy: -12).contains(point) {
            overTrash = true
            target = nil
            return
        }
        overTrash = false
        var best: SlotKey?
        var bestScore = CGFloat.greatestFiniteMagnitude
        for (key, rect) in frames {
            let horizontal = max(0, max(rect.minX - point.x, point.x - rect.maxX))
            let vertical = abs(point.y - rect.midY)
            let score = vertical + horizontal * 1.6
            if score < bestScore {
                bestScore = score
                best = key
            }
        }
        target = bestScore < 260 ? best : nil
    }

    func label(for payload: DragPayload, in program: [BNode]) -> (String, Color)? {
        switch payload {
        case .newBlock(let type):
            let sample = makeBlock(type)
            let text = blockLabel(type).replacingOccurrences(of: "%@", with: "…")
            return (text, sample.color)
        case .moveBlock(let id):
            guard let node = EditorOps.find(id: id, in: program) else { return nil }
            let text = blockLabel(node.type).replacingOccurrences(of: "%@", with: "…")
            return (text, node.color)
        }
    }
}

struct BlockDrag: ViewModifier {
    @EnvironmentObject var drag: DragController
    let payload: DragPayload
    let enabled: Bool
    let onDrop: () -> Void

    private var mine: Bool { drag.payload == payload }

    func body(content: Content) -> some View {
        content.gesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .named(EDITOR_SPACE))
                .onChanged { move in
                    guard enabled else { return }
                    if drag.payload == nil {
                        drag.begin(payload, at: move.location)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        UISound.blockPickUp.play()
                    } else if mine {
                        drag.move(to: move.location)
                    }
                }
                .onEnded { _ in
                    guard mine else { return }
                    let droppedOnTrash = drag.overTrash
                    onDrop()
                    if droppedOnTrash { UISound.blockDelete.play() } else { UISound.blockDrop.play() }
                    drag.cancel()
                }
        )
    }
}

extension View {
    func blockDrag(_ payload: DragPayload, enabled: Bool, onDrop: @escaping () -> Void) -> some View {
        modifier(BlockDrag(payload: payload, enabled: enabled, onDrop: onDrop))
    }
}

struct TrayWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 { value = next }
    }
}

struct DragGhost: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 13.5, weight: .medium))
            .foregroundStyle(.white)
            .lineLimit(1)
            .fixedSize()
            .padding(.leading, 12).padding(.trailing, 14)
            .padding(.top, 9).padding(.bottom, 8)
            .background(BlockShape().fill(color).shadow(color: .black.opacity(0.26), radius: 12, y: 6))
            .opacity(0.94)
    }
}
