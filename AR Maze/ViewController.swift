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

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var mazeIsSetUp = false // will become true once user taps to place maze entrance and maze is set up
    var mazeWidth: Float = 11.0 // treat width as left-to-right distance
    var mazeLength: Float = 11.0 // treat length as 3D-depth (ie. forward & backward)
    var mazeHeight: Float = 2.0 // currently set to low value so it's easy to see whole maze
    var unitLength: Float = 1.0 // length of each wall segment;
                                // must divide mazeLength and mazeWidth perfectly;
                                // must divide mazeWidth to produce an odd number so that maze entrance and exit are perfectly centralized
    var mazeEntrance: SCNVector3! // coordinates of where user taps to place maze entrance
    var theMaze: MazeGenerator!
    
    var waitTime: TimeInterval = 0
    var currentlyOb = false // to check if user is currently out of bounds (in a wall)
    var obWarningNode: SCNNode!
    
    // for manually-created 2x3 maze (currently not in use)
//    var widthWalls = [[1, 1, 1], [0, 0, 0], [1, 0, 1]]
//    var lengthWalls = [[1, 0, 0, 1], [1, 0, 0, 1]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.scene.physicsWorld.contactDelegate = self
        
        // creates the red warning node that will be displayed if user is out of bounds (in a wall)
        let obWarning = SCNBox(width: 0.1, height: 0.3, length: 0.1, chamferRadius: 0)
        let color = UIColor.red
        obWarning.materials.first?.diffuse.contents = color
        obWarningNode = SCNNode(geometry: obWarning)
        obWarningNode.position = SCNVector3Make(0, 0, -0.1)
        sceneView.pointOfView?.addChildNode(obWarningNode)
        
        addTapGestureToSceneView() // for when the user taps to set up the maze, place markers, etc.
        
        // generates 2D array for maze; determines where walls are
        // 1st parameter: no. of maze cells along width (left-right)
        // 2nd parameter: no. of maze cells along length (depth)
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
    
    // adds a small red sphere to the scene;
    // called when user taps any part of any wall to add a marker
    func addMarker(x: Float, y: Float, z: Float) {
        let marker = SCNSphere(radius: 0.025)
        let color = UIColor.red
        marker.materials.first?.diffuse.contents = color
        
        let markerNode = SCNNode()
        markerNode.geometry = marker
        markerNode.name = "marker"
        markerNode.position = SCNVector3(x, y, z)
        sceneView.scene.rootNode.addChildNode(markerNode)
    }
    
    // every corner of each maze cell has a pillar;
    // this function handles the adding of pillars
    func addPillar(xPos: Float, zPos: Float) {
        let pillar = SCNBox(width: 0.1, height: CGFloat(mazeHeight), length: 0.1, chamferRadius: 0)
        
        // for adding texture to pillars
        let pillarTexture = UIImage(named: "castleWall")
        let pillarMaterial = SCNMaterial()
        pillarMaterial.diffuse.contents = pillarTexture
        pillarMaterial.isDoubleSided = true
        pillar.materials = [pillarMaterial]
        
        let pillarNode = SCNNode()
        pillarNode.geometry = pillar
        pillarNode.position = SCNVector3(xPos, mazeEntrance.y + (mazeHeight/2), zPos)
        
        sceneView.scene.rootNode.addChildNode(pillarNode)
    }
    
    // handles the adding of wall segments
    func addWall(width: Float, length: Float, xPos: Float, zPos: Float) {
        let wall = SCNBox(width: CGFloat(width), height: CGFloat(mazeHeight), length: CGFloat(length), chamferRadius: 0)
        
        // for adding texture to walls
        let wallTexture = UIImage(named: "castleWall")
        let wallMaterial = SCNMaterial()
        wallMaterial.diffuse.contents = wallTexture
        wallMaterial.isDoubleSided = true
        wall.materials = [wallMaterial]

        let wallNode = SCNNode()
        wallNode.geometry = wall
        
        wallNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        wallNode.physicsBody?.categoryBitMask = PhysicsCategory.WallOrPillar
        wallNode.physicsBody?.contactTestBitMask = PhysicsCategory.Camera
        wallNode.physicsBody?.collisionBitMask = PhysicsCategory.None
        
        wallNode.position = SCNVector3(xPos, mazeEntrance.y + (mazeHeight/2), zPos)

        sceneView.scene.rootNode.addChildNode(wallNode)
    }
    
    //Generates a box to be used as the finish for the maze
    func addMazeFinish(width: Float, length: Float, xPos: Float, zPos: Float) {
        
        //Create block object
        let finishBlock = SCNBox(width: CGFloat(width), height: CGFloat(0.3), length: CGFloat(length), chamferRadius: 0)
        let finishMaterial = SCNMaterial()
        finishMaterial.diffuse.contents = UIImage(named: "exclamationBlock")
        finishMaterial.isDoubleSided = true
        finishBlock.materials = [finishMaterial]
        
        let finishNode = SCNNode()
        finishNode.geometry = finishBlock
        finishNode.position = SCNVector3(xPos, 0.1, zPos)
        finishNode.name = "finish"
        
        //Create text object
//        let finishText = SCNText()
//        let finishString = (string: "Congrats", extrusionDepth: 4)
//        finishText.string = finishString
//
//        let textNode = SCNNode()
//        textNode.geometry = finishText
//        finishNode.position = SCNVector3(xPos, 0.2, zPos)
//
//        //Add textnode to scene
//        sceneView.scene.rootNode.addChildNode(textNode)
        //Add block node to scene
        sceneView.scene.rootNode.addChildNode(finishNode)
    }
    
    // for user to place maze entrance;
    // function can be extended for special features in the near future
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // handles user's tap gestures
    @objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation)
        
        // checks if user taps a node (a wall or a marker);
        // if not, then user could be placing maze entrance, so checks if maze is already set up
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
        
        // this code only runs if user is taps a node
        if node.name == "marker" { // if node is a marker, removes it from scene
            node.removeFromParentNode()
        }
        // this code only runs if user taps the finish node
        else if node.name == "finish" {
            finishMaze()
        }
        else { // if node is a wall, adds marker to whatever part it that user tapped
            if let touchLocOnNode = hitTestResults.first?.worldCoordinates {
                addMarker(x: touchLocOnNode.x, y: touchLocOnNode.y, z: touchLocOnNode.z)
            }
        }
    }
    
    // handles contact between user and walls
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        print("contact")
        currentlyOb = true
    }
    
    func setUpMaze() {
        
        // determines position of top-left point of maze
        let topLeftPos = SCNVector3(mazeEntrance.x - mazeWidth/2, mazeEntrance.y, mazeEntrance.z - mazeLength)
        
        for j in 0..<Int(mazeLength/unitLength) {
            // builds walls for top-edges of each maze-cell (if there is supposed to be a wall there)
            for i in 0..<theMaze.width {
                addPillar(xPos: topLeftPos.x + Float(i)*unitLength, zPos: topLeftPos.z + Float(j)*unitLength)
                if (j == 0) { // these few lines ensure no wall is built where exit is supposed to be
                    if (i != (Int(mazeWidth/unitLength)) / 2) {
                        if (theMaze.maze[i][j] & Direction.north.rawValue) == 0 {
                            addWall(width: unitLength-0.1, length: 0.1, xPos: topLeftPos.x + 0.5*unitLength + Float(i)*unitLength, zPos: topLeftPos.z + Float(j)*unitLength)
                        }
                    }
                }
                else {
                    if (theMaze.maze[i][j] & Direction.north.rawValue) == 0 {
                        addWall(width: unitLength-0.1, length: 0.1, xPos: topLeftPos.x + 0.5*unitLength + Float(i)*unitLength, zPos: topLeftPos.z + Float(j)*unitLength)
                    }
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
            if i != (Int(mazeWidth/unitLength)) / 2 { // ensures no wall is built where entrance is supposed to be
                addWall(width: unitLength-0.1, length: 0.1, xPos: topLeftPos.x + 0.5*unitLength + Float(i)*unitLength, zPos: mazeEntrance.z)
            }
        }
        //Add maze finish block, currently at the entrance for checking
        //addMazeFinish(width: 0.3, length: 0.3, xPos: mazeEntrance.x, zPos: mazeEntrance.z)
        //Add maze finish to the exit
        addMazeFinish(width: 0.3, length: 0.3, xPos: mazeEntrance.x, zPos: mazeEntrance.z - mazeLength)
        
        //addBox(x: mazeEntrance.x, y: mazeHeight/4, z: mazeEntrance.z)
        
        addPillar(xPos: topLeftPos.x + mazeWidth, zPos: mazeEntrance.z)
        
        mazeIsSetUp = true
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if time > waitTime {
            spawnObCheckNode()
            currentlyOb = false
            removeFallenObCheckNodes()
            waitTime = time + TimeInterval(0.5)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if currentlyOb == true {
            obWarningNode.opacity = 1
        }
        else {
            obWarningNode.opacity = 0
        }
    }
    
    func spawnObCheckNode() {
        let obCheckSphere = SCNSphere(radius: 0.02)
        let obCheckNode = SCNNode(geometry: obCheckSphere)
        obCheckNode.opacity = 0
        
        obCheckNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        obCheckNode.physicsBody?.categoryBitMask = PhysicsCategory.Camera
        obCheckNode.physicsBody?.contactTestBitMask = PhysicsCategory.WallOrPillar
        obCheckNode.physicsBody?.collisionBitMask = PhysicsCategory.None
        
        obCheckNode.position = SCNVector3Make(0, 0, 0)
        sceneView.pointOfView?.addChildNode(obCheckNode)
    }
    
    func removeFallenObCheckNodes() {
//        if let cameraChildNodes = sceneView.pointOfView?.childNodes {
//            for node in cameraChildNodes {
//                if (node.presentation.position.y < 0) {
//                    node.removeFromParentNode()
//                }
//            }
//        }
        
    }
    
    //This function will eventually close the session and switch to the maze finished screen?
    func finishMaze() {
        performSegue(withIdentifier: "goToFinishSegue", sender: nil)
        
        //print ("Maze is finished")
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



