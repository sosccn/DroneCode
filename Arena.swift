import SwiftUI
import SceneKit

let CM = 0.01

private func c(_ hex: UInt32, alpha: CGFloat = 1) -> UIColor {
    UIColor(red: CGFloat((hex >> 16) & 0xff) / 255.0,
            green: CGFloat((hex >> 8) & 0xff) / 255.0,
            blue: CGFloat(hex & 0xff) / 255.0,
            alpha: alpha)
}

func lineGeometry(_ points: [SCNVector3], color: UIColor, opacity: CGFloat = 1) -> SCNGeometry {

    let pts = points.count >= 2 ? points : [SCNVector3Zero, SCNVector3Zero]
    let source = SCNGeometrySource(vertices: pts)
    var indices: [Int32] = []
    if pts.count >= 2 {
        for i in 0..<(pts.count - 1) {
            indices.append(Int32(i))
            indices.append(Int32(i + 1))
        }
    }
    let element = SCNGeometryElement(indices: indices, primitiveType: .line)
    let g = SCNGeometry(sources: [source], elements: [element])
    let m = SCNMaterial()
    m.diffuse.contents = color
    m.emission.contents = color
    m.lightingModel = .constant
    m.transparency = opacity
    g.materials = [m]
    return g
}

@MainActor
final class ArenaController {

    let scene = SCNScene()
    let cameraNode = SCNNode()

    private let droneGroup = SCNNode()
    private let droneInner = SCNNode()
    private var propNodes: [SCNNode] = []
    private var ledNode: SCNNode?
    private var ledLight: SCNLight?

    private let ringsRoot = SCNNode()
    private let obstaclesRoot = SCNNode()
    private var ringNodes: [SCNNode] = []

    private let groundMarker = SCNNode()
    private var dropLineNode = SCNNode()
    private var trailNode = SCNNode()
    private var trailPoints: [SCNVector3] = []

    var camMode: CameraMode = .orbit
    var theta: Double = 0.9
    var phi: Double = 1.05
    var radius: Double = 6.4
    private var curTarget = (x: 0.0, y: 0.5, z: -0.8)

    init() {
        buildStatic()
        buildDrone()
        buildGroundGuides()
        scene.rootNode.addChildNode(ringsRoot)
        scene.rootNode.addChildNode(obstaclesRoot)

        let cam = SCNCamera()
        cam.fieldOfView = 55
        cam.zNear = 0.05
        cam.zFar = 200
        cameraNode.camera = cam
        scene.rootNode.addChildNode(cameraNode)
        updateCamera(force: true)
    }

    private func buildStatic() {

        scene.background.contents = c(0xccd4e0)
        scene.fogColor = c(0xccd4e0)
        scene.fogStartDistance = 18
        scene.fogEndDistance = 46

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = c(0xffffff)
        ambient.light?.intensity = 620
        scene.rootNode.addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.color = c(0xffffff)
        sun.light?.intensity = 750
        sun.light?.castsShadow = true
        sun.light?.shadowMode = .deferred
        sun.light?.shadowRadius = 8
        sun.light?.shadowColor = UIColor.black.withAlphaComponent(0.18)
        sun.position = SCNVector3(4, 7, 3)
        sun.look(at: SCNVector3(0, 0, -1))
        scene.rootNode.addChildNode(sun)

        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial?.diffuse.contents = c(0xf8f8fa)
        floor.firstMaterial?.roughness.contents = 0.96
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)

        var gridPts: [SCNVector3] = []
        let half: Float = 20
        var i: Float = -20
        while i <= 20 {
            gridPts.append(SCNVector3(i, 0.002, -half))
            gridPts.append(SCNVector3(i, 0.002, half))
            gridPts.append(SCNVector3(-half, 0.002, i))
            gridPts.append(SCNVector3(half, 0.002, i))
            i += 1
        }
        var idx: [Int32] = []
        for k in stride(from: 0, to: gridPts.count, by: 2) {
            idx.append(Int32(k)); idx.append(Int32(k + 1))
        }
        let gsrc = SCNGeometrySource(vertices: gridPts)
        let gel = SCNGeometryElement(indices: idx, primitiveType: .line)
        let ggeo = SCNGeometry(sources: [gsrc], elements: [gel])
        let gm = SCNMaterial()
        gm.diffuse.contents = c(0xb9bfcb)
        gm.lightingModel = .constant
        gm.transparency = 0.9
        ggeo.materials = [gm]
        scene.rootNode.addChildNode(SCNNode(geometry: ggeo))

        let pad = SCNCylinder(radius: 0.42, height: 0.012)
        pad.firstMaterial?.diffuse.contents = c(0xdcdce2)
        let padNode = SCNNode(geometry: pad)
        padNode.position = SCNVector3(0, 0.006, 0)
        scene.rootNode.addChildNode(padNode)

        let padRing = SCNTorus(ringRadius: 0.44, pipeRadius: 0.012)
        padRing.firstMaterial?.diffuse.contents = c(0x0071e3)
        padRing.firstMaterial?.lightingModel = .constant
        let padRingNode = SCNNode(geometry: padRing)
        padRingNode.position = SCNVector3(0, 0.014, 0)
        scene.rootNode.addChildNode(padRingNode)

        let axisF = SCNNode(geometry: lineGeometry([SCNVector3(0, 0.012, 0), SCNVector3(0, 0.012, -3.2)],
                                                   color: c(0x0071e3), opacity: 0.85))
        scene.rootNode.addChildNode(axisF)
        let axisR = SCNNode(geometry: lineGeometry([SCNVector3(0, 0.012, 0), SCNVector3(3.2, 0.012, 0)],
                                                   color: c(0xff3b30), opacity: 0.85))
        scene.rootNode.addChildNode(axisR)

        for r in 1...4 {
            let ring = SCNTorus(ringRadius: CGFloat(r), pipeRadius: 0.007)
            ring.firstMaterial?.diffuse.contents = c(0xa8aeba)
            ring.firstMaterial?.lightingModel = .constant
            ring.firstMaterial?.transparency = 0.7
            let n = SCNNode(geometry: ring)
            n.position = SCNVector3(0, 0.006, 0)
            scene.rootNode.addChildNode(n)
        }

        scene.rootNode.addChildNode(trailNode)
    }

    private func buildDrone() {
        let shell = SCNMaterial()
        shell.diffuse.contents = c(0x1d1d1f)
        shell.metalness.contents = 0.35
        shell.roughness.contents = 0.42

        let dark = SCNMaterial()
        dark.diffuse.contents = c(0x0a0a0c)
        dark.metalness.contents = 0.4
        dark.roughness.contents = 0.6

        let trim = SCNMaterial()
        trim.diffuse.contents = c(0xff3b30)
        trim.emission.contents = c(0x4a0b06)
        trim.roughness.contents = 0.4

        let pale = SCNMaterial()
        pale.diffuse.contents = c(0xd1d1d6)
        pale.roughness.contents = 0.5

        let body = SCNBox(width: 0.21, height: 0.055, length: 0.24, chamferRadius: 0.02)
        body.materials = [shell]
        let bodyNode = SCNNode(geometry: body)
        droneInner.addChildNode(bodyNode)

        let canopy = SCNBox(width: 0.13, height: 0.04, length: 0.12, chamferRadius: 0.02)
        canopy.materials = [dark]
        let canopyNode = SCNNode(geometry: canopy)
        canopyNode.position = SCNVector3(0, 0.04, 0.01)
        droneInner.addChildNode(canopyNode)

        let stripe = SCNBox(width: 0.205, height: 0.008, length: 0.06, chamferRadius: 0.002)
        stripe.materials = [pale]
        let stripeNode = SCNNode(geometry: stripe)
        stripeNode.position = SCNVector3(0, 0.03, 0.09)
        droneInner.addChildNode(stripeNode)

        let nose = SCNCone(topRadius: 0, bottomRadius: 0.032, height: 0.07)
        nose.materials = [trim]
        let noseNode = SCNNode(geometry: nose)
        noseNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        noseNode.position = SCNVector3(0, 0.005, -0.14)
        droneInner.addChildNode(noseNode)

        let arms: [(Double, Double)] = [(0.135, 0.115), (-0.135, 0.115), (0.135, -0.115), (-0.135, -0.115)]
        for (i, a) in arms.enumerated() {
            let isFront = i >= 2
            let arm = SCNCylinder(radius: 0.012, height: 0.11)
            arm.materials = [shell]
            let armNode = SCNNode(geometry: arm)
            armNode.position = SCNVector3(Float(a.0 * 0.55), 0, Float(a.1 * 0.55))
            armNode.eulerAngles = SCNVector3(Float.pi / 2, 0, Float(atan2(a.0, a.1)))
            droneInner.addChildNode(armNode)

            let motor = SCNCylinder(radius: 0.022, height: 0.035)
            motor.materials = [dark]
            let motorNode = SCNNode(geometry: motor)
            motorNode.position = SCNVector3(Float(a.0), 0.02, Float(a.1))
            droneInner.addChildNode(motorNode)

            let guardRing = SCNTorus(ringRadius: 0.073, pipeRadius: 0.007)
            guardRing.materials = [isFront ? trim : pale]
            let guardNode = SCNNode(geometry: guardRing)
            guardNode.position = SCNVector3(Float(a.0), 0.035, Float(a.1))
            droneInner.addChildNode(guardNode)

            let prop = SCNNode()
            for k in 0..<2 {
                let blade = SCNBox(width: 0.13, height: 0.004, length: 0.018, chamferRadius: 0.002)
                let bm = SCNMaterial()
                bm.diffuse.contents = isFront ? c(0xff453a) : c(0xb8b8bf)
                bm.transparency = 0.92
                blade.materials = [bm]
                let bn = SCNNode(geometry: blade)
                bn.eulerAngles = SCNVector3(0, Float(Double(k) * Double.pi / 2), 0)
                prop.addChildNode(bn)
            }
            prop.position = SCNVector3(Float(a.0), 0.043, Float(a.1))
            prop.runAction(.repeatForever(.rotateBy(x: 0, y: 8, z: 0, duration: 0.35)))
            propNodes.append(prop)
            droneInner.addChildNode(prop)
        }

        let led = SCNSphere(radius: 0.022)
        let lm = SCNMaterial()
        lm.diffuse.contents = c(0xd1d1d6)
        lm.emission.contents = UIColor.black
        led.materials = [lm]
        let ledN = SCNNode(geometry: led)
        ledN.position = SCNVector3(0, -0.035, 0)
        droneInner.addChildNode(ledN)
        ledNode = ledN

        let l = SCNLight()
        l.type = .omni
        l.color = UIColor.black
        l.intensity = 0
        let lNode = SCNNode()
        lNode.light = l
        lNode.position = SCNVector3(0, -0.06, 0)
        droneInner.addChildNode(lNode)
        ledLight = l

        droneGroup.addChildNode(droneInner)
        droneGroup.castsShadow = true
        scene.rootNode.addChildNode(droneGroup)
    }

    private func buildGroundGuides() {
        let ring = SCNTorus(ringRadius: 0.17, pipeRadius: 0.014)
        ring.firstMaterial?.diffuse.contents = c(0x0071e3)
        ring.firstMaterial?.lightingModel = .constant
        ring.firstMaterial?.transparency = 0.6
        groundMarker.addChildNode(SCNNode(geometry: ring))

        let arrow = SCNCone(topRadius: 0, bottomRadius: 0.07, height: 0.15)
        arrow.firstMaterial?.diffuse.contents = c(0xff3b30)
        arrow.firstMaterial?.lightingModel = .constant
        arrow.firstMaterial?.transparency = 0.85
        let arrowNode = SCNNode(geometry: arrow)
        arrowNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        arrowNode.position = SCNVector3(0, 0, -0.3)
        groundMarker.addChildNode(arrowNode)

        groundMarker.position = SCNVector3(0, 0.012, 0)
        groundMarker.isHidden = true
        scene.rootNode.addChildNode(groundMarker)

        scene.rootNode.addChildNode(dropLineNode)
    }

    func rebuildMission(rings: [RingSpec], obstacles: [Obstacle]) {
        ringsRoot.childNodes.forEach { $0.removeFromParentNode() }
        obstaclesRoot.childNodes.forEach { $0.removeFromParentNode() }
        ringNodes = []

        for r in rings {
            let torus = SCNTorus(ringRadius: 0.45, pipeRadius: 0.035)
            let m = SCNMaterial()
            m.diffuse.contents = c(0xff9f0a)
            m.emission.contents = c(0x5c3a00)
            m.roughness.contents = 0.4
            torus.materials = [m]
            let n = SCNNode(geometry: torus)
            n.position = SCNVector3(Float(r.x * CM), Float(r.y * CM), Float(r.z * CM))

            n.eulerAngles = SCNVector3(Float.pi / 2, Float(r.rotY * .pi / 180), 0)
            ringsRoot.addChildNode(n)
            ringNodes.append(n)
        }

        for o in obstacles {
            let box = SCNBox(width: CGFloat(o.w * CM), height: CGFloat(o.h * CM),
                             length: CGFloat(o.d * CM), chamferRadius: 0.01)
            let m = SCNMaterial()
            m.diffuse.contents = c(0xd8d8de)
            m.roughness.contents = 0.9
            box.materials = [m]
            let n = SCNNode(geometry: box)
            n.position = SCNVector3(Float(o.x * CM), Float(o.h * CM / 2), Float(o.z * CM))
            obstaclesRoot.addChildNode(n)

            let edge = SCNBox(width: CGFloat(o.w * CM) + 0.01, height: 0.012,
                              length: CGFloat(o.d * CM) + 0.01, chamferRadius: 0.004)
            let em = SCNMaterial()
            em.diffuse.contents = c(0xff3b30)
            em.lightingModel = .constant
            em.transparency = 0.85
            edge.materials = [em]
            let en = SCNNode(geometry: edge)
            en.position = SCNVector3(Float(o.x * CM), Float(o.h * CM), Float(o.z * CM))
            obstaclesRoot.addChildNode(en)
        }
    }

    func markRingPassed(_ i: Int) {
        guard i < ringNodes.count, let m = ringNodes[i].geometry?.firstMaterial else { return }
        m.diffuse.contents = c(0x34c759)
        m.emission.contents = c(0x14532d)
    }

    func resetRingVisual() {
        for n in ringNodes {
            n.geometry?.firstMaterial?.diffuse.contents = c(0xff9f0a)
            n.geometry?.firstMaterial?.emission.contents = c(0x5c3a00)
        }
    }

    func addTrailPoint(x: Double, y: Double, z: Double) {
        trailPoints.append(SCNVector3(Float(x * CM), Float(y * CM), Float(z * CM)))
        if trailPoints.count > 1200 { trailPoints.removeFirst() }
        if trailPoints.count >= 2 {
            trailNode.geometry = lineGeometry(trailPoints, color: c(0x0071e3), opacity: 0.95)
        }
    }

    func clearTrail() {
        trailPoints = []
        trailNode.geometry = nil
    }

    func updateLED(_ rgb: [Int]) {
        guard rgb.count == 3 else { return }
        let color = UIColor(red: CGFloat(rgb[0]) / 255.0,
                            green: CGFloat(rgb[1]) / 255.0,
                            blue: CGFloat(rgb[2]) / 255.0, alpha: 1)
        let on = rgb[0] + rgb[1] + rgb[2] > 0
        ledNode?.geometry?.firstMaterial?.emission.contents = on ? color : UIColor.black
        ledLight?.color = on ? color : UIColor.black
        ledLight?.intensity = on ? 260 : 0
    }

    func sync(_ sim: SimState) {
        droneGroup.position = SCNVector3(Float(sim.x * CM), Float(sim.y * CM), Float(sim.z * CM))
        droneGroup.eulerAngles = SCNVector3(0, Float(sim.yaw * .pi / 180), 0)
        droneInner.eulerAngles = SCNVector3(Float(sim.pitch + sim.flipPitch), 0,
                                            Float(sim.roll + sim.flipRoll))

        let show = sim.y > 4
        groundMarker.isHidden = !show
        groundMarker.position = SCNVector3(Float(sim.x * CM), 0.012, Float(sim.z * CM))
        groundMarker.eulerAngles = SCNVector3(0, Float(sim.yaw * .pi / 180), 0)

        if show {
            dropLineNode.geometry = lineGeometry(
                [SCNVector3(Float(sim.x * CM), 0.012, Float(sim.z * CM)),
                 SCNVector3(Float(sim.x * CM), Float(sim.y * CM), Float(sim.z * CM))],
                color: c(0x0071e3), opacity: 0.45)
        } else {
            dropLineNode.geometry = nil
        }

        updateCamera(sim: sim)
    }

    func updateCamera(sim: SimState = SimState(), force: Bool = false) {
        let tx = sim.x * CM, ty = sim.y * CM, tz = sim.z * CM
        let follow = 0.12
        var target = (x: 0.0, y: 0.5, z: -0.8)

        switch camMode {
        case .orbit:
            target = (x: 0, y: 0.5, z: -0.8)
        case .follow, .fpv:
            target = (x: tx, y: ty, z: tz)
        case .top:
            target = (x: tx, y: 0, z: tz)
        }

        if force {
            curTarget = target
        } else {
            curTarget.x += (target.x - curTarget.x) * follow
            curTarget.y += (target.y - curTarget.y) * follow
            curTarget.z += (target.z - curTarget.z) * follow
        }

        switch camMode {
        case .fpv:
            let y = sim.yaw * .pi / 180
            let eye = SCNVector3(Float(tx - sin(y) * 0.12), Float(ty + 0.06), Float(tz - cos(y) * 0.12))
            cameraNode.position = eye
            cameraNode.eulerAngles = SCNVector3(0, Float(y), 0)
        case .top:
            let height = clamp(radius * 1.25, 3, 22)
            cameraNode.position = SCNVector3(Float(curTarget.x), Float(height), Float(curTarget.z + 0.001))
            cameraNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        default:
            let r = camMode == .follow ? clamp(radius * 0.5, 1.5, 9) : radius
            let ex = curTarget.x + r * sin(phi) * cos(theta)
            let ey = curTarget.y + r * cos(phi)
            let ez = curTarget.z + r * sin(phi) * sin(theta)
            cameraNode.position = SCNVector3(Float(ex), Float(max(0.25, ey)), Float(ez))
            cameraNode.look(at: SCNVector3(Float(curTarget.x), Float(curTarget.y), Float(curTarget.z)))
        }
    }

    func setOrbit(theta t: Double, phi p: Double) {
        theta = t
        phi = clamp(p, 0.12, 1.5)
    }

    func setRadius(_ r: Double) {
        radius = clamp(r, 1.4, 20)
    }

    func zoom(by factor: Double) {
        setRadius(radius / factor)
    }
}

struct ArenaView: UIViewRepresentable {
    let controller: ArenaController

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        v.scene = controller.scene
        v.pointOfView = controller.cameraNode
        v.allowsCameraControl = false
        v.antialiasingMode = .multisampling2X
        v.backgroundColor = UIColor(red: 0.800, green: 0.831, blue: 0.878, alpha: 1)
        v.isJitteringEnabled = false
        v.rendersContinuously = true
        return v
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.pointOfView = controller.cameraNode
    }
}
