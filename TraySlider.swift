import SwiftUI

struct TraySlider: View {
    let contentWidth: CGFloat
    let visibleWidth: CGFloat
    @Binding var offset: CGFloat

    @State private var dragStart: CGFloat?

    private var maxOffset: CGFloat { max(0, contentWidth - visibleWidth) }

    var body: some View {
        HStack(spacing: 8) {
            stepButton("chevron.left") {
                offset = max(0, offset - visibleWidth * 0.6)
            }

            GeometryReader { geo in
                let track = geo.size.width
                let ratio = contentWidth > 0 ? min(1, visibleWidth / contentWidth) : 1
                let thumb = max(46, track * ratio)
                let travel = max(1, track - thumb)
                let progress = maxOffset > 0 ? offset / maxOffset : 0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 0.90))
                        .frame(height: 8)
                    Capsule()
                        .fill(dragStart == nil ? Color(white: 0.62) : Theme.accent)
                        .frame(width: thumb, height: 8)
                        .offset(x: travel * progress)
                }
                .frame(height: 26)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let base: CGFloat
                            if let s = dragStart {
                                base = s
                            } else {
                                base = offset
                                dragStart = offset
                            }
                            let delta = g.translation.width / travel * maxOffset
                            offset = min(max(0, base + delta), maxOffset)
                        }
                        .onEnded { _ in dragStart = nil }
                )
            }
            .frame(height: 26)

            stepButton("chevron.right") {
                offset = min(maxOffset, offset + visibleWidth * 0.6)
            }
        }
        .onChange(of: maxOffset) { limit in
            if offset > limit { offset = limit }
        }
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) { action() }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.text2)
                .frame(width: 30, height: 26)
                .background(Theme.bg2)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
