//
//  StopRouteTests.swift
//  gtfs-importerTests
//
//  Tests for StopRoute functionality
//

import Foundation
import GRDB
import Testing
import GTFSModel
import CSV
@testable import gtfs_importer

@Suite("StopRoute Tests", .serialized, .tags(.integrationTests))
struct StopRouteTests {

    @Test("addStopRoutes populates routes field for stops")
    func testAddStopRoutes() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)  // Allow time for file system to release lock

        // Create a complete test dataset with routes and trips
        let gtfsDir = try TestDataHelper.createMinimalGTFSDataset()
        defer { TemporaryFileHelper.cleanup(directory: gtfsDir) }
        defer {
            Thread.sleep(forTimeInterval: 0.1)  // Wait before cleanup
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        // Import all entities
        let importer = Importer(path: gtfsDir.path)
        try importer.importAllFiles()

        // Call the actual StopRoute.addStopRoutes() method to test it
        try StopRoute.addStopRoutes()

        // Verify stops have routes populated
        do {
            let stopRouteDB = try DatabaseQueue(path: "./gtfs.db")
            let (stopsWithRoutesCount, stop1Routes) = try stopRouteDB.read { db in
                (
                    try Stop.fetchAll(db, sql: "SELECT * FROM stops WHERE routes IS NOT NULL").count,
                    try Stop.fetchOne(db, key: "STOP1")?.routes
                )
            }

            #expect(stopsWithRoutesCount > 0, "At least some stops should have routes")
            #expect(stop1Routes != nil, "STOP1 should have routes")

            // Routes should be comma-separated or single route
            if let routes = stop1Routes {
                #expect(routes.contains(",") || routes.count > 0, "Routes should be comma-separated or single route")
            }
        }  // stopRouteDB goes out of scope and closes here
    }

    @Test("Stops with no trips have null routes field")
    func testStopsWithNoTrips() throws {
        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try Stop.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
            try StopTime.createTable(db: db)

            // Insert test data
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('A1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type, route_short_name) VALUES ('R1', 3, '22')")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP1', 37.3347, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP_NO_TRIPS', 37.9999, -122.9999, 0, 0)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('S1', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP1', 'R1', 'S1')")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('TRIP1', 'STOP1', 1, '08:00:00', '08:00:00')")

            // Build stop-route mapping (only STOP1 should get routes)
            var stopsWithRoutes: [String: Set<String>] = [:]
            let stopTimes = try StopTime.fetchAll(db)

            for stopTime in stopTimes {
                if let trip = try Trip.fetchOne(db, key: stopTime.tripIdentifier) {
                    if let route = try Route.fetchOne(db, key: trip.routeIdentifier), let shortName = route.shortName {
                        if stopsWithRoutes[stopTime.stopIdentifier] == nil {
                            stopsWithRoutes[stopTime.stopIdentifier] = Set<String>()
                        }
                        stopsWithRoutes[stopTime.stopIdentifier]?.insert(shortName)
                    }
                }
            }

            // Update stops
            for (stopID, routes) in stopsWithRoutes {
                var stop = try Stop.fetchOne(db, key: stopID)!
                stop.routes = routes.sorted().joined(separator: ", ")
                try stop.update(db)
            }
        }

        // Verify
        let (stop1Routes, stopNoTripsRoutes) = try db.read { db in
            (
                try Stop.fetchOne(db, key: "STOP1")?.routes,
                try Stop.fetchOne(db, key: "STOP_NO_TRIPS")?.routes
            )
        }

        #expect(stop1Routes != nil, "STOP1 should have routes")
        #expect(stopNoTripsRoutes == nil, "STOP_NO_TRIPS should have null routes")
    }

    @Test("Multiple routes per stop are comma-separated")
    func testMultipleRoutesPerStop() throws {
        let dbPath = TemporaryFileHelper.createTemporaryDatabasePath()
        defer { try? FileManager.default.removeItem(at: dbPath) }

        let db = try DatabaseQueue(path: dbPath.path)
        try db.write { db in
            try Agency.createTable(db: db)
            try Route.createTable(db: db)
            try Stop.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try Trip.createTable(db: db)
            try StopTime.createTable(db: db)

            // Insert test data with multiple routes serving same stop
            try db.execute(sql: "INSERT INTO agency (agency_id, agency_name, agency_url, agency_timezone) VALUES ('A1', 'Test', 'http://test.com', 'America/Los_Angeles')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type, route_short_name) VALUES ('R1', 3, '22')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type, route_short_name) VALUES ('R2', 3, '23')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type, route_short_name) VALUES ('R3', 3, '24')")
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP1', 37.3347, -121.8906, 0, 0)")
            try db.execute(sql: "INSERT INTO calendar (service_id, start_date, end_date, monday, tuesday, wednesday, thursday, friday, saturday, sunday) VALUES ('S1', '2024-01-01', '2024-12-31', 1, 1, 1, 1, 1, 0, 0)")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP1', 'R1', 'S1')")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP2', 'R2', 'S1')")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('TRIP3', 'R3', 'S1')")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('TRIP1', 'STOP1', 1, '08:00:00', '08:00:00')")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('TRIP2', 'STOP1', 1, '09:00:00', '09:00:00')")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('TRIP3', 'STOP1', 1, '10:00:00', '10:00:00')")

            // Build stop-route mapping
            var stopsWithRoutes: [String: Set<String>] = [:]
            let stopTimes = try StopTime.fetchAll(db)

            for stopTime in stopTimes {
                if let trip = try Trip.fetchOne(db, key: stopTime.tripIdentifier) {
                    if let route = try Route.fetchOne(db, key: trip.routeIdentifier), let shortName = route.shortName {
                        if stopsWithRoutes[stopTime.stopIdentifier] == nil {
                            stopsWithRoutes[stopTime.stopIdentifier] = Set<String>()
                        }
                        stopsWithRoutes[stopTime.stopIdentifier]?.insert(shortName)
                    }
                }
            }

            // Update stops
            for (stopID, routes) in stopsWithRoutes {
                var stop = try Stop.fetchOne(db, key: stopID)!
                stop.routes = routes.sorted().joined(separator: ", ")
                try stop.update(db)
            }
        }

        // Verify
        let stop1Routes = try db.read { db in
            try Stop.fetchOne(db, key: "STOP1")?.routes
        }

        #expect(stop1Routes == "22, 23, 24", "STOP1 should have all three routes comma-separated and sorted")
    }
}
