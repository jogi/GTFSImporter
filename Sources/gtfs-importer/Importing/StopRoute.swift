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
        var stopsWithRoutes: [String: [String]] = [:]
        
        let trips: [TripInfo] = try dbQueue?.read { db in
            let request = Trip.including(required: Trip.route)
            return try TripInfo.fetchAll(db, request)
        } ?? []
        
        for trip in trips {
            guard let route = trip.route.shortName else {
                return
            }

            try dbQueue?.read { db in
                let stops = try StopTime
                    .filter(Column(StopTime.CodingKeys.tripIdentifier.rawValue) == trip.trip.identifier)
                    .fetchAll(db)

                for stop in stops {
                    if !(stopsWithRoutes[stop.stopIdentifier]?.contains(route) ?? false) {
                        stopsWithRoutes[stop.stopIdentifier] = (stopsWithRoutes[stop.stopIdentifier] ?? []) + [route]
                    }
                }
            }
        }
        
        for (key, value) in stopsWithRoutes {
            try dbQueue?.write { db in
                if var stop = try Stop.filter(Column(Stop.CodingKeys.identifier) == key).fetchOne(db) {
                    stop.routes = value.joined(separator: ", ")
                    try stop.update(db)
                }
            }
        }
        
    }
}

extension Route: FetchableRecord {
    static let trips = hasMany(Trip.self)
    var trips: QueryInterfaceRequest<Trip> { request(for: Route.trips) }
}

extension Trip: FetchableRecord {
    static let route = belongsTo(Route.self)
    var route: QueryInterfaceRequest<Route> { request(for: Trip.route) }
}

extension Stop: FetchableRecord {}

extension StopTime: FetchableRecord {
    public static var databaseDateDecodingStrategy = DatabaseDateDecodingStrategy.formatted(DateFormatter.hhmmss)
}

struct TripInfo: Decodable, FetchableRecord {
    var route: Route
    var trip: Trip
}
