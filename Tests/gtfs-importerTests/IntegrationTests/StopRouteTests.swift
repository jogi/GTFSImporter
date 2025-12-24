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
        defer {
            Thread.sleep(forTimeInterval: 0.1)  // Wait before cleanup
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        // Import real data using the importer
        let importer = Importer(path: TestDataHelper.smallRealTestDataPath())
        try importer.importAllFiles()

        // Call the actual StopRoute.addStopRoutes() method to test it
        try StopRoute.addStopRoutes()

        // Verify stops have routes populated
        do {
            let stopRouteDB = try DatabaseQueue(path: "./gtfs.db")
            let (stopsWithRoutesCount, stop4736Routes) = try stopRouteDB.read { db in
                (
                    try Stop.fetchAll(db, sql: "SELECT * FROM stops WHERE routes IS NOT NULL").count,
                    try Stop.fetchOne(db, key: "4736")?.routes
                )
            }

            #expect(stopsWithRoutesCount > 0, "At least some stops should have routes")
            #expect(stop4736Routes != nil, "Stop 4736 should have routes")

            // Routes should contain "Blue" for real VTA data
            if let routes = stop4736Routes {
                #expect(routes.contains("Blue"), "Routes should contain Blue line")
            }
        }  // stopRouteDB goes out of scope and closes here
    }

    @Test("Stops with no trips have null routes field")
    func testStopsWithNoTrips() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)
        defer {
            Thread.sleep(forTimeInterval: 0.1)
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        // Import real data first
        let importer = Importer(path: TestDataHelper.smallRealTestDataPath())
        try importer.importAllFiles()

        // Now add a stop that has no trips
        let db = try DatabaseQueue(path: "./gtfs.db")
        try db.write { db in
            try db.execute(sql: "INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding) VALUES ('STOP_NO_TRIPS', 37.9999, -122.9999, 0, 0)")
        }

        // Run addStopRoutes
        try StopRoute.addStopRoutes()

        // Verify
        let (stop4736Routes, stopNoTripsRoutes) = try db.read { db in
            (
                try Stop.fetchOne(db, key: "4736")?.routes,
                try Stop.fetchOne(db, key: "STOP_NO_TRIPS")?.routes
            )
        }

        #expect(stop4736Routes != nil, "Stop 4736 should have routes")
        #expect(stopNoTripsRoutes == nil, "STOP_NO_TRIPS should have null routes")
    }

    @Test("Multiple routes per stop are comma-separated")
    func testMultipleRoutesPerStop() throws {
        // Clean up any leftover databases
        try? FileManager.default.removeItem(atPath: "./gtfs.db")
        Thread.sleep(forTimeInterval: 0.2)
        defer {
            Thread.sleep(forTimeInterval: 0.1)
            try? FileManager.default.removeItem(atPath: "./gtfs.db")
        }

        // Import real data first
        let importer = Importer(path: TestDataHelper.smallRealTestDataPath())
        try importer.importAllFiles()

        // Add additional routes and trips to create multiple routes for same stop
        let db = try DatabaseQueue(path: "./gtfs.db")
        try db.write { db in
            // Add more routes
            try db.execute(sql: "INSERT INTO routes (route_id, route_type, route_short_name, agency_id) VALUES ('Green', 0, 'Green Line', 'VTA')")
            try db.execute(sql: "INSERT INTO routes (route_id, route_type, route_short_name, agency_id) VALUES ('Orange', 0, 'Orange Line', 'VTA')")

            // Add trips for these routes using existing service
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('GREEN_TRIP', 'Green', '268.2969.1')")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('ORANGE_TRIP', 'Orange', '268.2969.1')")

            // Add stop_times for the same stop (4736) on different routes
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('GREEN_TRIP', '4736', 1, '08:00:00', '08:00:00')")
            try db.execute(sql: "INSERT INTO stop_times (trip_id, stop_id, stop_sequence, arrival_time, departure_time) VALUES ('ORANGE_TRIP', '4736', 1, '09:00:00', '09:00:00')")
        }

        // Run addStopRoutes
        try StopRoute.addStopRoutes()

        // Verify
        let stop4736Routes = try db.read { db in
            try Stop.fetchOne(db, key: "4736")?.routes
        }

        #expect(stop4736Routes != nil, "Stop 4736 should have routes")

        // Should contain all three routes (Blue from import + Green + Orange we added)
        if let routes = stop4736Routes {
            #expect(routes.contains("Blue"), "Should contain Blue Line")
            #expect(routes.contains("Green"), "Should contain Green Line")
            #expect(routes.contains("Orange"), "Should contain Orange Line")
            #expect(routes.contains(","), "Multiple routes should be comma-separated")
        }
    }
}
