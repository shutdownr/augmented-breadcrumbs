//
//  MatrixCalc.swift
//  AugmentedBreadcrumbs
//
//  Created by Tim on 13.05.19.
//  Copyright © 2019 Tim. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

class MatrixCalc {
    static func transformMatrix(matrix: simd_float4x4, myLocation: CLLocation, newLocation: CLLocation) -> simd_float4x4{
        let distance = Float(newLocation.distance(from: myLocation))
        let bearing = myLocation.angleTo(location: newLocation)
        let position = vector_float4(0.0, 0.0, -distance, 0.0)
        let translationMatrix = self.translationMatrix(with: matrix_identity_float4x4, for: position)
        let rotationMatrix = rotateAroundY(with: matrix_identity_float4x4, for: Float(bearing + .pi))
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        return simd_mul(matrix, transformMatrix)
    }
    
    static func rotateAroundY(with matrix: matrix_float4x4, for degrees: Float) -> matrix_float4x4 {
        var matrix : matrix_float4x4 = matrix
        
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    static func translationMatrix(with matrix: matrix_float4x4, for translation : vector_float4) -> matrix_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
}
