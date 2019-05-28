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
    private var goalNode: SCNNode!
    private var frozen = false
    
    
    //var positions = [CLLocation(latitude: 52.047094, longitude: 12.043262), CLLocation(latitude: 52.047094, longitude: 14.043262), CLLocation(latitude: 50.047094, longitude: 14.043262), CLLocation(latitude: 48.047094, longitude: 14.043262), CLLocation(latitude: 48.047094, longitude: 12.043262), CLLocation(latitude: 48.047094, longitude: 10.043262), CLLocation(latitude: 50.047094, longitude: 10.043262),CLLocation(latitude: 52.047094, longitude: 10.043262)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationHelper = LocationHelper(onLocationUpdated: onLocationUpdate)

        NotificationCenter.default.addObserver(self, selector: #selector(settingsUpdated), name: UserDefaults.didChangeNotification, object: nil)

        goalPosition = CLLocation(latitude: 50.325696, longitude: 11.938760)
        settingsUpdated()
        initARSession()
    }

    @objc func settingsUpdated() {
        if let lat = UserDefaults.standard.string(forKey: "latitude_prefs"), let lon = UserDefaults.standard.string(forKey: "longitude_prefs") {
            if let latDouble = Double(lat), let lonDouble = Double(lon) {
                if CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: latDouble, longitude: lonDouble)) {
                    goalPosition = CLLocation(latitude: latDouble, longitude: lonDouble)
                }
            }
        }
    }

    func onLocationUpdate(location: CLLocation) {
        myPosition = location
        updateBreadcrumbs()
    }
    
    func updateBreadcrumbs() {
        if frozen { return }
        guard let myPos = myPosition, let goalPos = goalPosition, let pov = sceneView.pointOfView else { return }
        if myPos.coordinate.latitude.isNaN || myPos.coordinate.longitude.isNaN {
            return
        }

        debug.text = String(myPos.horizontalAccuracy)
        breadcrumbContainer.position = pov.position
        let goalMatrix = MatrixCalc.transformMatrix(matrix: matrix_identity_float4x4, myLocation: myPos, newLocation: goalPos)
        let goalVector = SCNVector3(goalMatrix.columns.3.x, 0, goalMatrix.columns.3.z)
        let distance = myPos.distance(from: goalPos)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        goalNode.position = goalVector

        let freezeDistance = myPos.horizontalAccuracy > 10 ? 10 + myPos.horizontalAccuracy / 2 : 10
        
        if distance < freezeDistance {
            for breadcrumb in breadcrumbs {
                breadcrumb.isHidden = true
                freeze.layer.borderWidth = 10
                freeze.layer.borderColor = UIColor.red.cgColor
            }
        }
        else {
            for breadcrumb in breadcrumbs {
                breadcrumb.isHidden = false
                freeze.layer.borderWidth = 0
                freeze.layer.borderColor = UIColor.green.cgColor
            }
        }
        
        let relativeDistance = Float(2 / distance)
        let relativeX = relativeDistance * goalVector.x
        let relativeZ = relativeDistance * goalVector.z
        let angle = atan2(relativeX, relativeZ)
        
        // Update breadcrumbs based on relative distance in x and z (y is equal to camera)
        
        for breadcrumb in breadcrumbs.enumerated() {
            breadcrumb.element.position = SCNVector3(relativeX * Float(breadcrumb.offset + 1), (Float(breadcrumb.offset) * 0.5) - 0.5, relativeZ * Float(breadcrumb.offset + 1))
            breadcrumb.element.eulerAngles = SCNVector3(0, angle, 0)
        }
        SCNTransaction.commit()
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

    func createARObjects() {
        breadcrumbContainer = SCNNode(geometry: nil)
        breadcrumbContainer.name = "BreadcrumbContainer"

        for i in 0...3 {
            let breadcrumbCone = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 0.15, height: 0.3))
            breadcrumbCone.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            breadcrumbCone.rotation = SCNVector4(1, 0, 0, Float.pi/2)
            let breadcrumb = SCNNode(geometry: nil)
            breadcrumb.addChildNode(breadcrumbCone)
            breadcrumb.name = "Breadcrumb \(i)"
            breadcrumb.isHidden = true

            breadcrumbs.append(breadcrumb)
            breadcrumbContainer.addChildNode(breadcrumb)
        }

        goalNode = SCNNode(geometry: SCNCylinder(radius: 0.5, height: 30))
        breadcrumbContainer.addChildNode(goalNode)

        sceneView.scene.rootNode.addChildNode(breadcrumbContainer)
    }

    func initARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            let alert = UIAlertController(title: "AR not supported", message: "It seems your device does not support Augmented Reality", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }

        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        sceneView.debugOptions = .showWorldOrigin
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.scene = scene

        createARObjects()
    }

    func resumeARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration)
    }

    func resetARSession() {
        locationHelper.resetKalmanFilter = true
        resumeARSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        resumeARSession()
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
        resetARSession()
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}
