import SwiftUI

struct SplitHandle: View {
    enum Axis { case horizontal, vertical }

    let axis: Axis
    let value: Double
    let range: ClosedRange<Double>
    let perPoint: Double
    let onChange: (Double) -> Void
    let onEnd: () -> Void

    @State private var start: Double?

    private var active: Bool { start != nil }

    var body: some View {
        ZStack {
            Color.white.opacity(0.001)
            Capsule()
                .fill(active ? Theme.accent : Color(white: 0.76))
                .frame(width: axis == .horizontal ? (active ? 5 : 4) : (active ? 52 : 44),
                       height: axis == .horizontal ? (active ? 52 : 44) : (active ? 5 : 4))
        }
        .frame(width: axis == .horizontal ? 18 : nil,
               height: axis == .vertical ? 18 : nil)
        .frame(maxWidth: axis == .vertical ? .infinity : nil,
               maxHeight: axis == .horizontal ? .infinity : nil)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    let base: Double
                    if let s = start {
                        base = s
                    } else {
                        base = value
                        start = value
                    }
                    let moved = axis == .horizontal ? g.translation.width : g.translation.height
                    let next = base + Double(moved) * perPoint
                    onChange(min(max(next, range.lowerBound), range.upperBound))
                }
                .onEnded { _ in
                    start = nil
                    onEnd()
                }
        )
    }
}
