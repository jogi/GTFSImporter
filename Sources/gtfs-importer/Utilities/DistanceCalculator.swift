//
//  DistanceCalculator.swift
//
//
//  Created by Claude Code on 12/12/25.
//

import Foundation

enum DistanceCalculator {
    /// Earth radius in meters
    private static let earthRadius: Double = 6378135

    /// Compute approximate distance between two points in meters using Haversine formula.
    /// Assumes the Earth is a sphere.
    ///
    /// - Parameters:
    ///   - lat1: Latitude of first point in degrees
    ///   - lon1: Longitude of first point in degrees
    ///   - lat2: Latitude of second point in degrees
    ///   - lon2: Longitude of second point in degrees
    /// - Returns: Distance in meters
    static func approximateDistance(
        lat1: Double,
        lon1: Double,
        lat2: Double,
        lon2: Double
    ) -> Double {
        // Convert degrees to radians
        let lat1Rad = lat1 * .pi / 180
        let lon1Rad = lon1 * .pi / 180
        let lat2Rad = lat2 * .pi / 180
        let lon2Rad = lon2 * .pi / 180

        // Haversine formula
        let dlat = sin(0.5 * (lat2Rad - lat1Rad))
        let dlng = sin(0.5 * (lon2Rad - lon1Rad))
        let x = dlat * dlat + dlng * dlng * cos(lat1Rad) * cos(lat2Rad)

        return earthRadius * (2 * atan2(sqrt(x), sqrt(max(0.0, 1.0 - x))))
    }
}
