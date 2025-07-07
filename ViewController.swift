
import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!

    var coachingOverlay = ARCoachingOverlayView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureARSession()
        addTapGesture()
        setupCoachingOverlay()
    }

    func configureARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        configuration.environmentTexturing = .automatic
        configuration.frameSemantics = .sceneDepth
        arView.session.run(configuration)
        arView.session.delegate = self
    }

    func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)
        if let result = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal).first {
            placeFurniture(at: result.worldTransform.translation)
        }
    }

    func placeFurniture(at position: SIMD3<Float>) {
        let furnitureEntity = try! Entity.loadModel(named: "chair") // provide a USDZ named "chair.usdz" in assets
        furnitureEntity.generateCollisionShapes(recursive: true)
        furnitureEntity.position = position
        let anchor = AnchorEntity(world: position)
        anchor.addChild(furnitureEntity)
        arView.scene.addAnchor(anchor)
    }

    func setupCoachingOverlay() {
        coachingOverlay.session = arView.session
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        NSLayoutConstraint.activate([
            coachingOverlay.topAnchor.constraint(equalTo: arView.topAnchor),
            coachingOverlay.bottomAnchor.constraint(equalTo: arView.bottomAnchor),
            coachingOverlay.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            coachingOverlay.trailingAnchor.constraint(equalTo: arView.trailingAnchor),
        ])
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if let sceneDepth = frame.sceneDepth {
            print("Scene depth info available with LiDAR resolution \(sceneDepth.depthMap.extent)")
        }
    }
}

extension simd_float4x4 {
    var translation: SIMD3<Float> {
        let translation = self.columns.3
        return SIMD3<Float>(translation.x, translation.y, translation.z)
    }
}
