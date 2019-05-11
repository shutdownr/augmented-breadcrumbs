//
//  LocationExtension.swift
//  AugmentedBreadcrumbs
//
//  Created by Tim on 10.05.19.
//  Copyright © 2019 Tim. All rights reserved.
//
import Foundation
import CoreLocation

extension CLLocation{
    
    func angleTo(location: CLLocation) -> Double {
        let lat1 = DegreeHelper.degreesToRadians(degrees: location.coordinate.latitude)
        let lon1 = DegreeHelper.degreesToRadians(degrees: location.coordinate.longitude)
        let lat2 = DegreeHelper.degreesToRadians(degrees: self.coordinate.latitude)
        let lon2 = DegreeHelper.degreesToRadians(degrees: self.coordinate.longitude)
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        var degrees = DegreeHelper.radiansToDegrees(radians: radiansBearing)
        degrees = (degrees + 180).truncatingRemainder(dividingBy: 360)
        return degrees
    }
    
    func getXZDistance(location: CLLocation, currentHeading: Double) -> (x: Double, z: Double) {
        let distanceToPosition = self.distance(from: location)
        let angleToPosition = self.angleTo(location: location)
        let userAngleToPosition = angleToPosition + currentHeading
        let x = -distanceToPosition * sin(DegreeHelper.degreesToRadians(degrees: userAngleToPosition))
        let z = -distanceToPosition * cos(DegreeHelper.degreesToRadians(degrees: userAngleToPosition))
        return (x: x, z: z)
    }
}

private class DegreeHelper {
    static func degreesToRadians(degrees: Double) -> Double {
        return degrees * .pi / 180
    }
    static func radiansToDegrees(radians: Double) -> Double {
        return radians * 180 / .pi
    }
}
