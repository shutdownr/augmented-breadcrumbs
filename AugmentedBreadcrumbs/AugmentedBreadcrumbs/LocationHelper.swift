//
//  LocationHelper.swift
//  AugmentedBreadcrumbs
//
//  Created by Tim on 10.05.19.
//  Copyright © 2019 Tim. All rights reserved.
//

import Foundation
import CoreLocation
import HCKalmanFilter

class LocationHelper: NSObject, CLLocationManagerDelegate {
    
    private var locationManager: CLLocationManager
    private var onLocationUpdate: (CLLocation) -> Void
    private var kalmanFilter: HCKalmanAlgorithm?
    public var resetKalmanFilter: Bool = false
    
    init(onLocationUpdated: @escaping (_ position: CLLocation) -> Void) {
        locationManager = CLLocationManager()
        
        if CLLocationManager.authorizationStatus() == .notDetermined || CLLocationManager.authorizationStatus() == .denied {
            locationManager.requestWhenInUseAuthorization()
        }
        
        onLocationUpdate = onLocationUpdated
        locationManager.startUpdatingLocation()
        
        super.init()
        locationManager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc = locations.last!
        
        if kalmanFilter == nil {
            kalmanFilter = HCKalmanAlgorithm(initialLocation: loc)
            onLocationUpdate(loc)
        }
        else {
            if resetKalmanFilter {
                kalmanFilter!.resetKalman(newStartLocation: loc)
                resetKalmanFilter = false
            }
            else {
                let kalmanLocation = kalmanFilter!.processState(currentLocation: loc)
                onLocationUpdate(kalmanLocation)
            }
        }
    }
}
