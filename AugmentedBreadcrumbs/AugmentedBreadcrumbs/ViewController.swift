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
    private var frozen = false
    private var cameraPosition: simd_float4x4?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationHelper = LocationHelper(onHeadingUpdated: onHeadingUpdate, onLocationUpdated: onLocationUpdate)
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showWorldOrigin]
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        sceneView.scene = scene
        sceneView.session.delegate = self
        
        for i in 0...2 {
            let breadcrumb = SCNNode(geometry: SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.05))
            breadcrumb.name = "Breadcrumb \(i)"
            breadcrumb.isHidden = true
            
            breadcrumbs.append(breadcrumb)
            sceneView.scene.rootNode.addChildNode(breadcrumb)
        }
        
        goalPosition = CLLocation(latitude: 50, longitude: 12)
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
    
    private var first = true
    func updateBreadcrumbs() {
        if frozen { return }
        guard let heading = myHeading, var myPos = myPosition, let goalPos = goalPosition else { return }
        myPos = CLLocation(latitude: 51, longitude: 12)
        let xzTotalDistance = myPos.getXZDistance(location: goalPos, currentHeading: heading)
        let distance = myPos.distance(from: goalPos)
        if distance < 10 {
            for breadcrumb in breadcrumbs {
                breadcrumb.isHidden = true
                freeze.layer.borderWidth = 10
                freeze.layer.borderColor = UIColor.red.cgColor
            }
            return
        }
        let relativeDistance = 2 / distance
        let relativeX = relativeDistance * xzTotalDistance.x
        let relativeZ = relativeDistance * xzTotalDistance.z
        guard let camPos = cameraPosition else { return }
        
        //var yAngle = Float.pi - atan2f( (2*q.y*q.w)-(2*q.x*q.z), 1-(2*pow(q.y,2))-(2*pow(q.z,2)))
        var yAngle = asin(camPos.columns.2.x) // Get y rotation angle
        if yAngle < (2/3) * .pi || yAngle > (4/3) * .pi { // exclude irrelevant angles (also filters first few callbacks, which are nonsense)
            return
        }
        yAngle += .pi // Rotate 180 degrees around y
        
        // Gets camera translation only
        var newWorldOrigin = simd_float4x4(
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
        )

        // Set new world origin
        sceneView.session.setWorldOrigin(relativeTransform: newWorldOrigin)

        // Update breadcrumbs based on relative distance in x and z (y is equal to camera)
        for breadcrumb in breadcrumbs.enumerated() {
            breadcrumb.element.position = SCNVector3(relativeX * Double(breadcrumb.offset + 1), 0, relativeZ * Double(breadcrumb.offset + 1))
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
