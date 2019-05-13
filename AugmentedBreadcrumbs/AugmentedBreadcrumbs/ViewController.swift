//
//  ViewController.swift
//  AugmentedBreadcrumbs
//
//  Created by Tim on 10.05.19.
//  Copyright © 2019 Tim. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var freeze: UIButton!
    @IBOutlet weak var debug: UILabel!
    
    private var locationHelper : LocationHelper!
    private var myPosition: CLLocation?
    private var myHeading: Double?
    private var goalPosition: CLLocation?
    private var breadcrumbs: [SCNNode] = []
    private var breadcrumbContainer: SCNNode!
    private var frozen = false
    private var cameraPosition: simd_float4x4?
    
    @IBAction func reset(_ sender: Any) {
        guard let pov = sceneView.pointOfView else { return }
        breadcrumbContainer.position = pov.position
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationHelper = LocationHelper(onHeadingUpdated: onHeadingUpdate, onLocationUpdated: onLocationUpdate)
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showWorldOrigin]
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        sceneView.scene = scene
        sceneView.session.delegate = self
        
        
        breadcrumbContainer = SCNNode(geometry: SCNSphere(radius: 0.01))
        breadcrumbContainer.name = "BreadcrumbContainer"
        
        for i in 0...3 {
            let breadcrumb = SCNNode(geometry: SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.05))
            breadcrumb.name = "Breadcrumb \(i)"
            breadcrumb.isHidden = true
            
            breadcrumbs.append(breadcrumb)
            breadcrumbContainer.addChildNode(breadcrumb)
        }
        
        sceneView.scene.rootNode.addChildNode(breadcrumbContainer)
        
        goalPosition = CLLocation(latitude: 50.047094, longitude: 12.043262)
    }
    
    func onHeadingUpdate(heading: Double) {
        myHeading = heading
        updateBreadcrumbs()
    }
    
    func onLocationUpdate(location: CLLocation) {
        myPosition = location
        //updateBreadcrumbs()
    }
    
    @IBAction func freeze(_ sender: Any) {
        frozen = !frozen
        if frozen {
            freeze.layer.borderColor = UIColor.cyan.cgColor
            freeze.layer.borderWidth = 10
        }
        else {
            freeze.layer.borderWidth = 0
        }
    }

    func transformMatrix(matrix: simd_float4x4, myLocation: CLLocation, newLocation: CLLocation) -> simd_float4x4{
        let distance = Float(newLocation.distance(from: myLocation))
        let bearing = myLocation.angleTo(location: newLocation)
        let position = vector_float4(0.0, 0.0, -distance, 0.0)
        let translationMatrix = self.translationMatrix(with: matrix_identity_float4x4, for: position)
        let rotationMatrix = rotateAroundY(with: matrix_identity_float4x4, for: Float(bearing + .pi))
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        return simd_mul(matrix, transformMatrix)
    }
    
    func rotateAroundY(with matrix: matrix_float4x4, for degrees: Float) -> matrix_float4x4 {
        var matrix : matrix_float4x4 = matrix
        
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    func translationMatrix(with matrix: matrix_float4x4, for translation : vector_float4) -> matrix_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    func updateBreadcrumbs() {
        if frozen { return }
        guard let myPos = myPosition, let goalPos = goalPosition else { return }
        
        let goalMatrix = transformMatrix(matrix: matrix_identity_float4x4, myLocation: myPos, newLocation: goalPos)
        let goalVector = SCNVector3(goalMatrix.columns.3.x, 0, goalMatrix.columns.3.z)
        let distance = myPos.distance(from: goalPos)
    
        if distance < 10 {
            for breadcrumb in breadcrumbs {
                breadcrumb.isHidden = true
                freeze.layer.borderWidth = 10
                freeze.layer.borderColor = UIColor.red.cgColor
            }
            return
        }
        
        let relativeDistance = Float(2 / distance)
        let relativeX = relativeDistance * goalVector.x
        let relativeZ = relativeDistance * goalVector.z

        // Update breadcrumbs based on relative distance in x and z (y is equal to camera)
        for breadcrumb in breadcrumbs.enumerated() {
            breadcrumb.element.position = SCNVector3(relativeX * Float(breadcrumb.offset + 1), 0, relativeZ * Float(breadcrumb.offset + 1))
            if breadcrumb.element.isHidden {
                breadcrumb.element.isHidden = false
                freeze.layer.borderWidth = 0
                freeze.layer.borderColor = UIColor.green.cgColor
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        cameraPosition = frame.camera.transform
    }
    
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
/*print("D")
 
 var yAngle = asin(camPos.columns.2.x) // Get y rotation angle
 print(yAngle)
 debug.text = "\(yAngle)"
 /*
 if yAngle > (1/3) * .pi || yAngle < (-1/3) * .pi { // exclude irrelevant angles (also filters first few callbacks, which are nonsense)
 return
 }*/
 
 print("E")
 if first {
 yAngle += .pi // Rotate 180 degrees around y
 first = false
 }
 
 
 
 // Gets camera translation only
 /*var newWorldOrigin = simd_float4x4(
 float4(x: 1, y: 0, z: 0, w: 0),
 float4(x: 0, y: 1, z: 0, w: 0),
 float4(x: 0, y: 0, z: 1, w: 0),
 float4(x: camPos.columns.3.x, y: camPos.columns.3.y, z: camPos.columns.3.z, w: 1)
 )
 
 // Applies y-rotation only
 newWorldOrigin *= simd_float4x4(
 float4(x: cos(yAngle), y: 0, z: sin(yAngle), w: 0),
 float4(x: 0, y: 1, z: 0, w: 0),
 float4(x: -sin(yAngle), y: 0, z: cos(yAngle), w: 0),
 float4(x: 0, y: 0, z: 0, w: 1)
 )*/
 
 // Gets camera translation only
 var newContainerPos = simd_float4x4(
 float4(x: 1, y: 0, z: 0, w: 0),
 float4(x: 0, y: 1, z: 0, w: 0),
 float4(x: 0, y: 0, z: 1, w: 0),
 float4(x: camPos.columns.3.x, y: camPos.columns.3.y, z: camPos.columns.3.z, w: 1)
 )
 
 // Applies y-rotation only
 newContainerPos *= simd_float4x4(
 float4(x: cos(yAngle), y: 0, z: sin(yAngle), w: 0),
 float4(x: 0, y: 1, z: 0, w: 0),
 float4(x: -sin(yAngle), y: 0, z: cos(yAngle), w: 0),
 float4(x: 0, y: 0, z: 0, w: 1)
 )
 */
