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
        let tripIds = try String.fetchAll(db, sql: """
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
        return try StopTimeRecord.fetchAll(db, sql: """
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
    private static func interpolateStopTimes(forTripId tripId: String, in db: Database) throws -> [InterpolatedStopTime] {
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

            // Check if this stop has an arrival time (is a timepoint)
            if let arrivalTime = st.arrivalTime, !arrivalTime.isEmpty {
                currentTimepoint = st
                distanceBetweenTimepoints = 0
                distanceTraveledBetweenTimepoints = 0

                // Find the next timepoint and calculate total distance
                if i + 1 < stopTimes.count {
                    var k = i + 1
                    distanceBetweenTimepoints += DistanceCalculator.approximateDistance(
                        lat1: stopTimes[k-1].stopLat,
                        lon1: stopTimes[k-1].stopLon,
                        lat2: stopTimes[k].stopLat,
                        lon2: stopTimes[k].stopLon
                    )

                    while k < stopTimes.count && (stopTimes[k].arrivalTime == nil || stopTimes[k].arrivalTime!.isEmpty) {
                        k += 1
                        if k < stopTimes.count {
                            distanceBetweenTimepoints += DistanceCalculator.approximateDistance(
                                lat1: stopTimes[k-1].stopLat,
                                lon1: stopTimes[k-1].stopLon,
                                lat2: stopTimes[k].stopLat,
                                lon2: stopTimes[k].stopLon
                            )
                        }
                    }

                    if k < stopTimes.count {
                        nextTimepoint = stopTimes[k]
                    }
                }

                // Add this timepoint
                interpolated.append(InterpolatedStopTime(
                    tripId: st.tripId,
                    stopId: st.stopId,
                    stopSequence: st.stopSequence,
                    arrivalTime: timeToSecondsSinceMidnight(arrivalTime),
                    isTimepoint: true
                ))
            } else {
                // This stop needs interpolation
                guard let current = currentTimepoint,
                      let next = nextTimepoint,
                      i > 0 else {
                    // Can't interpolate without surrounding timepoints
                    continue
                }

                // Calculate distance from previous stop
                distanceTraveledBetweenTimepoints += DistanceCalculator.approximateDistance(
                    lat1: stopTimes[i-1].stopLat,
                    lon1: stopTimes[i-1].stopLon,
                    lat2: st.stopLat,
                    lon2: st.stopLon
                )

                // Calculate interpolated time
                let distancePercent = distanceBetweenTimepoints > 0
                    ? distanceTraveledBetweenTimepoints / distanceBetweenTimepoints
                    : 0

                let currentTime = timeToSecondsSinceMidnight(current.arrivalTime!)
                let nextTime = timeToSecondsSinceMidnight(next.arrivalTime!)
                let totalTime = nextTime - currentTime
                let timeEstimate = Int(round(Double(totalTime) * distancePercent)) + currentTime

                interpolated.append(InterpolatedStopTime(
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
            try db.execute(sql: """
                UPDATE stop_times
                SET arrival_time = ?,
                    departure_time = ?,
                    timepoint = ?
                WHERE trip_id = ?
                AND stop_id = ?
                AND stop_sequence = ?
            """, arguments: [
                formatSecondsSinceMidnight(stopTime.arrivalTime),
                formatSecondsSinceMidnight(stopTime.arrivalTime),
                stopTime.isTimepoint ? 1 : 0,
                stopTime.tripId,
                stopTime.stopId,
                stopTime.stopSequence
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
