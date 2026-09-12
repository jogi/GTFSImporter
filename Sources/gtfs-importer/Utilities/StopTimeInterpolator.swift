//
//  StopTimeInterpolator.swift
//
//
//  Created by Claude Code on 12/12/25.
//

import Foundation
import GRDB
import GTFSModel
import OSLog

enum StopTimeInterpolator {
    /// Earth radius in meters
    private static let earthRadius: Double = 6_378_135

    /// Compute approximate distance between two points in meters using Haversine formula.
    /// Assumes the Earth is a sphere.
    ///
    /// - Parameters:
    ///   - lat1: Latitude of first point in degrees
    ///   - lon1: Longitude of first point in degrees
    ///   - lat2: Latitude of second point in degrees
    ///   - lon2: Longitude of second point in degrees
    /// - Returns: Distance in meters
    private static func approximateDistance(
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

    struct StopTimeRecord: Codable, FetchableRecord {
        var tripId: String
        var arrivalTime: String?
        var stopId: String
        var stopSequence: UInt
        var stopLat: Double
        var stopLon: Double

        enum CodingKeys: String, CodingKey {
            case tripId = "trip_id"
            case arrivalTime = "arrival_time"
            case stopId = "stop_id"
            case stopSequence = "stop_sequence"
            case stopLat = "stop_lat"
            case stopLon = "stop_lon"
        }
    }

    struct InterpolatedStopTime {
        var tripId: String
        var stopId: String
        var stopSequence: UInt
        var arrivalTime: Int  // seconds since midnight
        var isTimepoint: Bool
    }

    /// Interpolate stop times for all trips
    static func interpolateStopTimes(in db: Database) throws {
        Logger.importer.info("Starting stop time interpolation...")

        // Get all trip IDs
        let tripIds = try String.fetchAll(
            db,
            sql: """
                    SELECT DISTINCT trip_id FROM stop_times ORDER BY trip_id
                """)

        Logger.importer.info("Interpolating stop times for \(tripIds.count) trips")

        var interpolatedCount = 0
        var tripCount = 0

        for tripId in tripIds {
            let interpolated = try interpolateStopTimes(forTripId: tripId, in: db)
            try updateStopTimes(interpolated, in: db)
            interpolatedCount += interpolated.count
            tripCount += 1

            // Log progress every 1000 trips
            if tripCount % 1000 == 0 {
                Logger.importer.info("Interpolated \(tripCount) trips...")
            }
        }

        Logger.importer.info("Interpolated \(interpolatedCount) stop times for \(tripCount) trips")
    }

    /// Get stop times for a trip with stop coordinates
    private static func getStopTimes(forTripId tripId: String, in db: Database) throws -> [StopTimeRecord] {
        return try StopTimeRecord.fetchAll(
            db,
            sql: """
                    SELECT
                        stops.stop_lat,
                        stops.stop_lon,
                        stop_times.trip_id,
                        stop_times.arrival_time,
                        stop_times.stop_id,
                        stop_times.stop_sequence
                    FROM stop_times
                    JOIN stops ON stops.stop_id = stop_times.stop_id
                    WHERE stop_times.trip_id = ?
                    ORDER BY stop_times.stop_sequence
                """, arguments: [tripId])
    }

    /// Interpolate stop times for a single trip
    /// Only returns stop times that actually needed interpolation (had missing arrival_time)
    private static func interpolateStopTimes(forTripId tripId: String, in db: Database) throws -> [InterpolatedStopTime]
    {
        let stopTimes = try getStopTimes(forTripId: tripId, in: db)

        guard !stopTimes.isEmpty else {
            return []
        }

        var interpolated: [InterpolatedStopTime] = []
        var currentTimepoint: StopTimeRecord?
        var nextTimepoint: StopTimeRecord?
        var distanceBetweenTimepoints: Double = 0
        var distanceTraveledBetweenTimepoints: Double = 0

        for i in 0..<stopTimes.count {
            let st = stopTimes[i]

            // Check if this stop has an arrival time
            if let arrivalTime = st.arrivalTime, !arrivalTime.isEmpty {
                // This stop already has a time - don't touch it, preserve CSV timepoint value
                currentTimepoint = st
                nextTimepoint = nil
                distanceBetweenTimepoints = 0
                distanceTraveledBetweenTimepoints = 0

                // Find the next timepoint and calculate total distance
                if i + 1 < stopTimes.count {
                    var k = i + 1
                    distanceBetweenTimepoints += approximateDistance(
                        lat1: stopTimes[k - 1].stopLat,
                        lon1: stopTimes[k - 1].stopLon,
                        lat2: stopTimes[k].stopLat,
                        lon2: stopTimes[k].stopLon
                    )

                    while k < stopTimes.count && (stopTimes[k].arrivalTime == nil || stopTimes[k].arrivalTime!.isEmpty)
                    {
                        k += 1
                        if k < stopTimes.count {
                            distanceBetweenTimepoints += approximateDistance(
                                lat1: stopTimes[k - 1].stopLat,
                                lon1: stopTimes[k - 1].stopLon,
                                lat2: stopTimes[k].stopLat,
                                lon2: stopTimes[k].stopLon
                            )
                        }
                    }

                    if k < stopTimes.count {
                        nextTimepoint = stopTimes[k]
                    }
                }

                // Don't add to interpolated array - leave this stop's CSV values as-is
            } else {
                // This stop needs interpolation
                guard let current = currentTimepoint,
                    let next = nextTimepoint,
                    i > 0
                else {
                    // Can't interpolate without surrounding timepoints
                    continue
                }

                // Calculate distance from previous stop
                distanceTraveledBetweenTimepoints += approximateDistance(
                    lat1: stopTimes[i - 1].stopLat,
                    lon1: stopTimes[i - 1].stopLon,
                    lat2: st.stopLat,
                    lon2: st.stopLon
                )

                // Calculate interpolated time
                let distancePercent =
                    distanceBetweenTimepoints > 0
                    ? distanceTraveledBetweenTimepoints / distanceBetweenTimepoints
                    : 0

                let currentTime = timeToSecondsSinceMidnight(current.arrivalTime!)
                let nextTime = timeToSecondsSinceMidnight(next.arrivalTime!)
                let totalTime = nextTime - currentTime
                let timeEstimate = Int(round(Double(totalTime) * distancePercent)) + currentTime

                // Only add stops that actually needed interpolation
                interpolated.append(
                    InterpolatedStopTime(
                        tripId: st.tripId,
                        stopId: st.stopId,
                        stopSequence: st.stopSequence,
                        arrivalTime: timeEstimate,
                        isTimepoint: false
                    ))
            }
        }

        return interpolated
    }

    /// Update stop times in database with interpolated values
    private static func updateStopTimes(_ interpolated: [InterpolatedStopTime], in db: Database) throws {
        for stopTime in interpolated {
            try db.execute(
                sql: """
                        UPDATE stop_times
                        SET arrival_time = ?,
                            departure_time = ?,
                            timepoint = ?
                        WHERE trip_id = ?
                        AND stop_id = ?
                        AND stop_sequence = ?
                    """,
                arguments: [
                    formatSecondsSinceMidnight(stopTime.arrivalTime),
                    formatSecondsSinceMidnight(stopTime.arrivalTime),
                    stopTime.isTimepoint ? 1 : 0,
                    stopTime.tripId,
                    stopTime.stopId,
                    stopTime.stopSequence,
                ])
        }
    }

    /// Convert HH:MM:SS time string to seconds since midnight
    private static func timeToSecondsSinceMidnight(_ time: String) -> Int {
        let components = time.split(separator: ":").compactMap { Int($0) }
        guard components.count == 3 else { return 0 }
        return components[0] * 3600 + components[1] * 60 + components[2]
    }

    /// Format seconds since midnight as HH:MM:SS
    private static func formatSecondsSinceMidnight(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds / 60) % 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
