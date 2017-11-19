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
    
    var mazeIsSetUp = false // will become true once user taps to place maze entrance and maze is set up
    var mazeWidth: Float = 3.0 // treat width as left-to-right distance
    var mazeLength: Float = 3.0 // treat length as 3D-depth (ie. forward & backward)
    var mazeHeight: Float = 0.3 // currently set to low value so it's easy to see whole maze
    var unitLength: Float = 0.5 // length of each wall segment; must divide mazeLength and mazeWidth perfectly
    var mazeEntrance: SCNVector3! // coordinates of where user taps to place maze entrance
    
    // for manually-created 2x3 maze (currently not in use)
//    var widthWalls = [[1, 1, 1], [0, 0, 0], [1, 0, 1]]
//    var lengthWalls = [[1, 0, 0, 1], [1, 0, 0, 1]]
    
    var theMaze: MazeGenerator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        addTapGestureToSceneView() // allows user to tap to place maze entrance
        
        // generates 2D array for maze; determines where walls are
        // 1st parameter: no. of maze cells along width (depth)
        // 2nd parameter: no. of maze cells along length (left-right)
        // note: each cell can have a wall on its top and/or left
        theMaze = MazeGenerator(Int(mazeWidth/unitLength), Int(mazeLength/unitLength))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sceneView.session.pause()
    }
    
    // for manually-created maze (currently not in use)
//    func buildMaze() {
//
//        // determines position of top-left point of maze
//        let topLeftPos = SCNVector3(mazeEntrance.x - mazeWidth/2, mazeEntrance.y, mazeEntrance.z - mazeLength)
//
//        // builds maze pillars
//        for z in 0...Int(mazeLength/unitLength) {
//            for x in 0...Int(mazeWidth/unitLength) {
//                addPillar(xPos: topLeftPos.x + Float(x)*unitLength, zPos: topLeftPos.z + Float(z)*unitLength)
//            }
//        }
//
//        // builds width walls (left-right)
//        for (rowIndex, row) in widthWalls.enumerated() {
//            for (wallIndex, wall) in row.enumerated() {
//                if wall == 1 {
//                    addWall(width: unitLength-0.1, length: 0.1, xPos: topLeftPos.x + 0.5*unitLength + Float(wallIndex)*unitLength, zPos: topLeftPos.z + Float(rowIndex)*unitLength)
//                }
//            }
//        }
//
//        // builds length walls (depth)
//        for (rowIndex, row) in lengthWalls.enumerated() {
//            for (wallIndex, wall) in row.enumerated() {
//                if wall == 1 {
//                    addWall(width: 0.1, length: unitLength-0.1, xPos: topLeftPos.x + Float(wallIndex)*unitLength, zPos: topLeftPos.z + 0.5*unitLength + Float(rowIndex)*unitLength)
//                }
//            }
//        }
//
//        mazeIsSetUp = true
//    }
    
    // function that we can use for testing:
    // places a small white box at a specified location
    func addBox(x: Float, y: Float, z: Float) {
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3(x, y, z)
        
        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    // every corner of each maze cell has a pillar;
    // this function handles the adding of pillars
    func addPillar(xPos: Float, zPos: Float) {
        let box = SCNBox(width: 0.1, height: CGFloat(mazeHeight), length: 0.1, chamferRadius: 0)
        
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3(xPos, mazeEntrance.y + (mazeHeight/2), zPos)
        
        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    // handles the adding of wall segments
    func addWall(width: Float, length: Float, xPos: Float, zPos: Float) {
        let box = SCNBox(width: CGFloat(width), height: CGFloat(mazeHeight), length: CGFloat(length), chamferRadius: 0)

        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3(xPos, mazeEntrance.y + (mazeHeight/2), zPos)

        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    // for user to place maze entrance;
    // function can be extended for special features in the near future
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
                    setUpMaze() // sets up maze once maze entrance has been positioned
                    
                    // for manually-created maze (currently not in use)
                    // buildMaze()
                }
            }
            return
        }
        // node.removeFromParentNode()
    }
    
    func setUpMaze() {
        
        // determines position of top-left point of maze
        let topLeftPos = SCNVector3(mazeEntrance.x - mazeWidth/2, mazeEntrance.y, mazeEntrance.z - mazeLength)
        
        for j in 0..<Int(mazeLength/unitLength) {
            // builds walls for top-edges of each maze-cell (if there is supposed to be a wall there)
            for i in 0..<theMaze.width {
                addPillar(xPos: topLeftPos.x + Float(i)*unitLength, zPos: topLeftPos.z + Float(j)*unitLength)
                if (theMaze.maze[i][j] & Direction.north.rawValue) == 0 {
                    addWall(width: unitLength-0.1, length: 0.1, xPos: topLeftPos.x + 0.5*unitLength + Float(i)*unitLength, zPos: topLeftPos.z + Float(j)*unitLength)
                }
            }
            addPillar(xPos: topLeftPos.x + mazeWidth, zPos: topLeftPos.z + Float(j)*unitLength)
            
            // builds walls for left-edges of each maze-cell (if there is supposed to be a wall there)
            for i in 0..<Int(mazeWidth/unitLength) {
                if (theMaze.maze[i][j] & Direction.west.rawValue) == 0 {
                    addWall(width: 0.1, length: unitLength-0.1, xPos: topLeftPos.x + Float(i)*unitLength, zPos: topLeftPos.z + 0.5*unitLength + Float(j)*unitLength)
                }
            }
            addWall(width: 0.1, length: unitLength-0.1, xPos: topLeftPos.x + mazeWidth, zPos: topLeftPos.z + 0.5*unitLength + Float(j)*unitLength)
        }
        
        // manually builds last row of walls since the row isn't auto-generated
        for i in 0..<Int(mazeWidth/unitLength) {
            addPillar(xPos: topLeftPos.x + Float(i)*unitLength, zPos: mazeEntrance.z)
            addWall(width: unitLength-0.1, length: 0.1, xPos: topLeftPos.x + 0.5*unitLength + Float(i)*unitLength, zPos: mazeEntrance.z)
        }
        addPillar(xPos: topLeftPos.x + mazeWidth, zPos: mazeEntrance.z)
        
        mazeIsSetUp = true
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



