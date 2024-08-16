//
//  File.swift
//  
//
//  Created by Vashishtha Jogi on 8/11/24.
//

import Foundation
import GRDB
import GTFSModel
import OSLog

struct StopRoute {
    static var dbQueue: DatabaseQueue? {
        return try? DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    public static func addStopRoutes() throws {
        let startTime = Date()

        var stopsWithRoutes: [String: [String]] = [:]
        
        let trips: [TripInfo] = try dbQueue?.read { db in
            let request = Trip.including(required: Trip.route).group([Column(Trip.CodingKeys.routeIdentifier), Column(Trip.CodingKeys.serviceIdentifier), Column(Trip.CodingKeys.headSign), Column(Trip.CodingKeys.shapeIdentifier)])
            return try TripInfo.fetchAll(db, request)
        } ?? []
        
        Logger.importer.log("Fetched \(trips.count) trips")
        
        let tripRoutes: [String: String] = {
            var values: [String: String] = [:]
            for trip in trips {
                values[trip.trip.identifier] = trip.route.shortName
            }
            return values
        }()
        
        let stopTimes: [StopTime] = try dbQueue?.read { db in
            let tripIDs = tripRoutes.map { $0.0 }
            return try StopTime.fetchAll(db, sql: """
            SELECT * from \(StopTime.databaseTableName) WHERE \(StopTime.CodingKeys.tripIdentifier.rawValue) IN (\(databaseQuestionMarks(count: tripIDs.count)))
            """, arguments: StatementArguments(tripIDs))
        } ?? []
        
        Logger.importer.log("Fetched \(stopTimes.count) stop_times")
        
        for stopTime in stopTimes {
            guard let route = tripRoutes[stopTime.tripIdentifier] else {
                return
            }
         
            if !(stopsWithRoutes[stopTime.stopIdentifier]?.contains(route) ?? false) {
                stopsWithRoutes[stopTime.stopIdentifier] = (stopsWithRoutes[stopTime.stopIdentifier] ?? []) + [route]
            }
        }

        Logger.importer.log("Calculated \(stopTimes.count) stopsWithRoutes")
        
        for (key, value) in stopsWithRoutes {
            try dbQueue?.write { db in
                if var stop = try Stop.filter(Column(Stop.CodingKeys.identifier) == key).fetchOne(db) {
                    stop.routes = value.joined(separator: ", ")
                    try stop.update(db)
                }
            }
        }
        
        let endTime = Date()
        
        let duration = String(format: "%.2f", endTime.timeIntervalSince(startTime))
        print("Updated \(String(stopsWithRoutes.count).green) stops with routes in \(duration.green) seconds")
    }
}
