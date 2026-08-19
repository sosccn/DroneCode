import SwiftUI

let NOTCH_X: CGFloat = 16
let NOTCH_W: CGFloat = 18
let NOTCH_D: CGFloat = 5
let BLOCK_CORNER: CGFloat = 7
let RAIL_W: CGFloat = 14

struct BlockShape: Shape {
    var topNotch = true
    var bottomTab = true
    var corner: CGFloat = BLOCK_CORNER

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let x0 = rect.minX, x1 = max(rect.minX + corner * 2 + NOTCH_X + NOTCH_W, rect.maxX)
        let y0 = rect.minY, y1 = rect.maxY
        let nx = x0 + NOTCH_X

        p.move(to: CGPoint(x: x0, y: y0 + corner))
        p.addQuadCurve(to: CGPoint(x: x0 + corner, y: y0), control: CGPoint(x: x0, y: y0))

        if topNotch {
            p.addLine(to: CGPoint(x: nx, y: y0))
            p.addLine(to: CGPoint(x: nx + NOTCH_D, y: y0 + NOTCH_D))
            p.addLine(to: CGPoint(x: nx + NOTCH_W - NOTCH_D, y: y0 + NOTCH_D))
            p.addLine(to: CGPoint(x: nx + NOTCH_W, y: y0))
        }

        p.addLine(to: CGPoint(x: x1 - corner, y: y0))
        p.addQuadCurve(to: CGPoint(x: x1, y: y0 + corner), control: CGPoint(x: x1, y: y0))
        p.addLine(to: CGPoint(x: x1, y: y1 - corner))
        p.addQuadCurve(to: CGPoint(x: x1 - corner, y: y1), control: CGPoint(x: x1, y: y1))

        if bottomTab {
            p.addLine(to: CGPoint(x: nx + NOTCH_W, y: y1))
            p.addLine(to: CGPoint(x: nx + NOTCH_W - NOTCH_D, y: y1 + NOTCH_D))
            p.addLine(to: CGPoint(x: nx + NOTCH_D, y: y1 + NOTCH_D))
            p.addLine(to: CGPoint(x: nx, y: y1))
        }

        p.addLine(to: CGPoint(x: x0 + corner, y: y1))
        p.addQuadCurve(to: CGPoint(x: x0, y: y1 - corner), control: CGPoint(x: x0, y: y1))
        p.closeSubpath()
        return p
    }
}

struct StartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let x0 = rect.minX, x1 = rect.maxX, y0 = rect.minY, y1 = rect.maxY
        let topCorner: CGFloat = 15
        let nx = x0 + NOTCH_X

        p.move(to: CGPoint(x: x0, y: y0 + topCorner))
        p.addQuadCurve(to: CGPoint(x: x0 + topCorner, y: y0),
                       control: CGPoint(x: x0, y: y0))
        p.addLine(to: CGPoint(x: x1 - topCorner, y: y0))
        p.addQuadCurve(to: CGPoint(x: x1, y: y0 + topCorner),
                       control: CGPoint(x: x1, y: y0))
        p.addLine(to: CGPoint(x: x1, y: y1 - BLOCK_CORNER))
        p.addQuadCurve(to: CGPoint(x: x1 - BLOCK_CORNER, y: y1), control: CGPoint(x: x1, y: y1))
        p.addLine(to: CGPoint(x: nx + NOTCH_W, y: y1))
        p.addLine(to: CGPoint(x: nx + NOTCH_W - NOTCH_D, y: y1 + NOTCH_D))
        p.addLine(to: CGPoint(x: nx + NOTCH_D, y: y1 + NOTCH_D))
        p.addLine(to: CGPoint(x: nx, y: y1))
        p.addLine(to: CGPoint(x: x0 + BLOCK_CORNER, y: y1))
        p.addQuadCurve(to: CGPoint(x: x0, y: y1 - BLOCK_CORNER), control: CGPoint(x: x0, y: y1))
        p.closeSubpath()
        return p
    }
}

struct FootShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let x0 = rect.minX, x1 = rect.maxX, y0 = rect.minY, y1 = rect.maxY
        let nx = x0 + NOTCH_X
        p.move(to: CGPoint(x: x0, y: y0))
        p.addLine(to: CGPoint(x: x1 - BLOCK_CORNER, y: y0))
        p.addQuadCurve(to: CGPoint(x: x1, y: y0 + BLOCK_CORNER), control: CGPoint(x: x1, y: y0))
        p.addLine(to: CGPoint(x: x1, y: y1 - BLOCK_CORNER))
        p.addQuadCurve(to: CGPoint(x: x1 - BLOCK_CORNER, y: y1), control: CGPoint(x: x1, y: y1))
        p.addLine(to: CGPoint(x: nx + NOTCH_W, y: y1))
        p.addLine(to: CGPoint(x: nx + NOTCH_W - NOTCH_D, y: y1 + NOTCH_D))
        p.addLine(to: CGPoint(x: nx + NOTCH_D, y: y1 + NOTCH_D))
        p.addLine(to: CGPoint(x: nx, y: y1))
        p.addLine(to: CGPoint(x: x0, y: y1))
        p.closeSubpath()
        return p
    }
}
