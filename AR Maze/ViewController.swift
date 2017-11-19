//
//  ViewController.swift
//  AR Maze
//
//  Created by William Leung on 11/16/17.
//  Copyright © 2017 Wai Kiet William Leung. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var mazeIsSetUp = false
    var mazeLength: Float = 2.0
    var mazeWidth: Float = 3.0
    var mazeHeight: Float = 2.0
    var unitLength: Float = 1.0
    var mazeEntrance: SCNVector3!
    
    var widthWalls = [[1, 1, 1], [0, 0, 0], [1, 0, 1]]
    var lengthWalls = [[1, 0, 0, 1], [1, 0, 0, 1]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        addTapGestureToSceneView()
        
        // Create a new scene
        // let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        // sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func setUpMaze() {
        addBox(x: mazeEntrance.x, y: mazeEntrance.y, z: mazeEntrance.z)
        
        let topLeftPos = SCNVector3(mazeEntrance.x - mazeWidth/2, mazeEntrance.y, mazeEntrance.z - mazeLength)
        
        for z in 0...Int(mazeLength/unitLength) {
            for x in 0...Int(mazeWidth/unitLength) {
                addPillar(xPos: topLeftPos.x + unitLength*Float(x), zPos: topLeftPos.z + unitLength*Float(z))
            }
        }
        
        for (rowIndex, row) in widthWalls.enumerated() {
            for (wallIndex, wall) in row.enumerated() {
                if wall == 1 {
                    addWall(width: 0.9, length: 0.1, xPos: topLeftPos.x + 0.5 + Float(wallIndex), zPos: topLeftPos.z + Float(rowIndex))
                }
            }
        }
        
        for (rowIndex, row) in lengthWalls.enumerated() {
            for (wallIndex, wall) in row.enumerated() {
                if wall == 1 {
                    addWall(width: 0.1, length: 0.9, xPos: topLeftPos.x + Float(wallIndex), zPos: topLeftPos.z + 0.5 + Float(rowIndex))
                }
            }
        }
        
        mazeIsSetUp = true
    }
    
    func addBox(x: Float, y: Float, z: Float) {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3(x, y, z)
        
        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    func addPillar(xPos: Float, zPos: Float) {
        let box = SCNBox(width: 0.1, height: CGFloat(mazeHeight), length: 0.1, chamferRadius: 0)
        
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3(xPos, mazeEntrance.y + (mazeHeight/2), zPos)
        
        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    func addWall(width: Float, length: Float, xPos: Float, zPos: Float) {
        let box = SCNBox(width: CGFloat(width), height: CGFloat(mazeHeight), length: CGFloat(length), chamferRadius: 0)

        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3(xPos, mazeEntrance.y + (mazeHeight/2), zPos)

        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation)
        guard let node = hitTestResults.first?.node else {
            if mazeIsSetUp == false {
                let hitTestResultsWithFeaturePoints = sceneView.hitTest(tapLocation, types: .featurePoint)
                
                if let hitTestResultWithFeaturePoints = hitTestResultsWithFeaturePoints.first {
                    let translation = hitTestResultWithFeaturePoints.worldTransform.translation
                    mazeEntrance = SCNVector3(x: translation.x, y: translation.y, z: translation.z)
                    setUpMaze()
                }
            }
            return
        }
        // node.removeFromParentNode()
    }
    

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
/*
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}



