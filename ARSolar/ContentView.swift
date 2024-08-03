//
//  ContentView.swift
//  ARSolar
//
//  Created by Parth Antala on 8/3/24.
//

import SwiftUI
import ARKit
import SceneKit

struct ContentView: View {
    @StateObject private var viewModel = ARViewModel()

    var body: some View {
        ARViewWrapper(sceneView: viewModel.sceneView)
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                viewModel.setupAR()
            }
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        viewModel.handleTap()
                    }
            )
    }
}

struct ARViewWrapper: UIViewRepresentable {
    let sceneView: ARSCNView

    func makeUIView(context: Context) -> ARSCNView {
        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

class ARViewModel: NSObject, ObservableObject, ARSCNViewDelegate {
    let sceneView = ARSCNView()
    private var scaledNodes = Set<SCNNode>()
    
    override init() {
        super.init()
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        sceneView.debugOptions = []
    }

    func setupAR() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal] // Detect horizontal planes
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func handleTap() {
        let center = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
        let results = sceneView.hitTest(center, types: .existingPlaneUsingExtent)

        guard let hitResult = results.first else {
            print("No surface detected")
            return
        }

        addSolarSystem(at: hitResult)
    }


    func addSolarSystem(at hitResult: ARHitTestResult) {
        // Define radii (make planets larger compared to the sun)
        let sunRadius: Float = 0.1 / 2
        let mercuryRadius: Float = 0.02 / 2
        let venusRadius: Float = 0.03 / 2
        let earthRadius: Float = 0.04 / 2
        let marsRadius: Float = 0.035 / 2
        let jupiterRadius: Float = 0.08 / 2
        let saturnRadius: Float = 0.07 / 2
        let uranusRadius: Float = 0.05 / 2
        let neptuneRadius: Float = 0.045 / 2
        
        // Function to create a planet with the specified parameters
        func createPlanet(name: String, radius: Float, textureName: String) -> SCNNode {
            let geometry = SCNSphere(radius: CGFloat(radius))
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "art.scnassets/\(textureName)")
            geometry.materials = [material]

            let node = SCNNode(geometry: geometry)
            node.name = name
            return node
        }
        
        // Function to create a dotted orbit
        func createDottedOrbit(radius: Float) -> SCNNode {
            let orbitNode = SCNNode()
            
            let numberOfDots = 100
            let dotRadius: CGFloat = 0.001
            let distanceBetweenDots: Float = 0.01
            
            for i in 0..<numberOfDots {
                let angle = Float(i) * 2.0 * Float.pi / Float(numberOfDots)
                let x = radius * cos(angle)
                let z = radius * sin(angle)
                
                let dotGeometry = SCNSphere(radius: dotRadius)
                let dotMaterial = SCNMaterial()
                dotMaterial.diffuse.contents = UIColor.white
                dotGeometry.materials = [dotMaterial]
                
                let dotNode = SCNNode(geometry: dotGeometry)
                dotNode.position = SCNVector3(x, 0, z)
                orbitNode.addChildNode(dotNode)
            }
            
           
            return orbitNode
        }

        // Create the sun and planets
        let sunNode = createPlanet(name: "sun", radius: sunRadius, textureName: "sun.jpg")
        let mercuryNode = createPlanet(name: "mercury", radius: mercuryRadius, textureName: "mercury.jpg")
        let venusNode = createPlanet(name: "venus", radius: venusRadius, textureName: "venus.jpg")
        let earthNode = createPlanet(name: "earth", radius: earthRadius, textureName: "earth.jpg")
        let marsNode = createPlanet(name: "mars", radius: marsRadius, textureName: "mars.jpg")
        let jupiterNode = createPlanet(name: "jupiter", radius: jupiterRadius, textureName: "jupiter.jpg")
        let saturnNode = createPlanet(name: "saturn", radius: saturnRadius, textureName: "saturn.jpg")
        let uranusNode = createPlanet(name: "uranus", radius: uranusRadius, textureName: "uranus.jpg")
        let neptuneNode = createPlanet(name: "neptune", radius: neptuneRadius, textureName: "neptune.jpg")

        // Central position for the sun
        let centerPosition = hitResult.worldTransform.columns.3

        // Add the sun node
        sunNode.position = SCNVector3(centerPosition.x, centerPosition.y, centerPosition.z)
        sceneView.scene.rootNode.addChildNode(sunNode)

        // Define orbit radii
        let orbitRadii: [Float] = [0.15 / 2, 0.25 / 2, 0.35 / 2, 0.45 / 2, 0.55 / 2, 0.65 / 2, 0.75 / 2, 0.85 / 2]

        // Add orbits
        for radius in orbitRadii {
            let orbitNode = createDottedOrbit(radius: radius)
            orbitNode.position = SCNVector3(centerPosition.x, centerPosition.y, centerPosition.z)
            sceneView.scene.rootNode.addChildNode(orbitNode)
        }

        // Position planets on their orbits
        let planets: [(name: String, node: SCNNode, distance: Float)] = [
            (name: "mercury", node: mercuryNode, distance: orbitRadii[0]),
            (name: "venus", node: venusNode, distance: orbitRadii[1]),
            (name: "earth", node: earthNode, distance: orbitRadii[2]),
            (name: "mars", node: marsNode, distance: orbitRadii[3]),
            (name: "jupiter", node: jupiterNode, distance: orbitRadii[4]),
            (name: "saturn", node: saturnNode, distance: orbitRadii[5]),
            (name: "uranus", node: uranusNode, distance: orbitRadii[6]),
            (name: "neptune", node: neptuneNode, distance: orbitRadii[7])
        ]
        
        // Position planets on orbits
        for (index, planet) in planets.enumerated() {
            let angle = 2 * Float.pi * Float(index) / Float(planets.count)
            let xOffset = planet.distance * cos(angle)
            let zOffset = planet.distance * sin(angle)
            
            planet.node.position = SCNVector3(centerPosition.x + xOffset, centerPosition.y, centerPosition.z + zOffset)
            sceneView.scene.rootNode.addChildNode(planet.node)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
                sceneView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
            let location = gestureRecognize.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: [:])
            
        if let tappedNode = hitResults.first?.node {
                if scaledNodes.contains(tappedNode) {
                    scaleDownNode(tappedNode)
                    scaledNodes.remove(tappedNode)
                } else {
                    scaleUpNode(tappedNode)
                    scaledNodes.insert(tappedNode)
                }
            }
        }
    
    func scaleUpNode(_ node: SCNNode) {
        let raiseAction = SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 0.5)
            let scaleUpAction = SCNAction.scale(to: 1.5, duration: 0.5)
            let scaleDownAction = SCNAction.scale(to: 1.0, duration: 0.5)
        
        let groupAction = SCNAction.group([raiseAction, scaleUpAction])
        let sequence = SCNAction.sequence([groupAction, scaleDownAction])
            node.runAction(sequence)
        }
    
    func scaleDownNode(_ node: SCNNode) {
            let lowerAction = SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 0.5)
            let scaleDownAction = SCNAction.scale(to: 1.0, duration: 0.5)
            let groupAction = SCNAction.group([lowerAction])
            let sequence = SCNAction.sequence([groupAction])
            
            node.runAction(sequence)
        }



    func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session failed: \(error.localizedDescription)")
    }

    func sessionWasInterrupted(_ session: ARSession) {
        print("Session was interrupted")
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        print("Session interruption ended")
        session.run(ARWorldTrackingConfiguration(), options: [.resetTracking, .removeExistingAnchors])
    }
}
