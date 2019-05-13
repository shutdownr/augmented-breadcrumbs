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

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var freeze: UIButton!
    @IBOutlet weak var debug: UILabel!
    
    private var locationHelper : LocationHelper!
    private var myPosition: CLLocation?
    private var goalPosition: CLLocation?
    private var breadcrumbs: [SCNNode] = []
    private var breadcrumbContainer: SCNNode!
    private var frozen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationHelper = LocationHelper(onLocationUpdated: onLocationUpdate)
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showWorldOrigin]
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        sceneView.scene = scene
        
        
        breadcrumbContainer = SCNNode(geometry: SCNSphere(radius: 0.01))
        breadcrumbContainer.name = "BreadcrumbContainer"
        
        for i in 0...3 {
            let breadcrumbCone = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 0.15, height: 0.3))
            breadcrumbCone.rotation = SCNVector4(0, 0, 1, -Double.pi/2)
            breadcrumbCone.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            let breadcrumb = SCNNode(geometry: nil)
            breadcrumb.addChildNode(breadcrumbCone)
            breadcrumb.name = "Breadcrumb \(i)"
            breadcrumb.isHidden = true
            
            breadcrumbs.append(breadcrumb)
            breadcrumbContainer.addChildNode(breadcrumb)
        }
        
        sceneView.scene.rootNode.addChildNode(breadcrumbContainer)
        
        goalPosition = CLLocation(latitude: 50.047094, longitude: 12.043262)
    }

    func onLocationUpdate(location: CLLocation) {
        myPosition = location
        updateBreadcrumbs()
    }
    
    func updateBreadcrumbs() {
        if frozen { return }
        guard let myPos = myPosition, let goalPos = goalPosition else { return }
        
        let goalMatrix = MatrixCalc.transformMatrix(matrix: matrix_identity_float4x4, myLocation: myPos, newLocation: goalPos)
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
    
    @IBAction func reset(_ sender: Any) {
        guard let pov = sceneView.pointOfView else { return }
        breadcrumbContainer.position = pov.position
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
