//
//  TestDataHelper.swift
//  gtfs-importerTests
//
//  Helper utilities for test data management
//

import Foundation

enum TestDataHelper {

    /// Returns the path to the full VTA test data
    static func fullTestDataPath() -> String {
        // Tests/testData/ directory
        let currentFile = URL(fileURLWithPath: #file)
        let testsDir = currentFile
            .deletingLastPathComponent()  // TestUtilities
            .deletingLastPathComponent()  // gtfs-importerTests
            .deletingLastPathComponent()  // Tests

        return testsDir.appendingPathComponent("testData").path
    }

    /// Creates a temporary CSV file with given headers and rows
    static func createTemporaryCSV(
        fileName: String,
        headers: [String],
        rows: [[String]]
    ) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let csvPath = tempDir.appendingPathComponent(fileName)

        var csvContent = headers.joined(separator: ",") + "\n"
        for row in rows {
            csvContent += row.joined(separator: ",") + "\n"
        }

        try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)
        return csvPath
    }

    /// Creates a minimal GTFS dataset in a temporary directory
    static func createMinimalGTFSDataset() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let gtfsDir = tempDir.appendingPathComponent("minimal-gtfs-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: gtfsDir, withIntermediateDirectories: true)

        // Create agency.txt
        let agencyCSV = """
        agency_id,agency_name,agency_url,agency_timezone
        AGENCY1,Test Transit,https://test.example.com,America/Los_Angeles
        """
        try agencyCSV.write(to: gtfsDir.appendingPathComponent("agency.txt"), atomically: true, encoding: .utf8)

        // Create routes.txt
        let routesCSV = """
        route_id,agency_id,route_short_name,route_long_name,route_type
        ROUTE1,AGENCY1,22,Palo Alto - San Jose,3
        ROUTE2,AGENCY1,23,De Anza College - Alum Rock,3
        """
        try routesCSV.write(to: gtfsDir.appendingPathComponent("routes.txt"), atomically: true, encoding: .utf8)

        // Create stops.txt
        let stopsCSV = """
        stop_id,stop_name,stop_lat,stop_lon,location_type,wheelchair_boarding
        STOP1,First Street,37.3347,-121.8906,0,0
        STOP2,Second Street,37.3357,-121.8916,0,0
        STOP3,Third Street,37.3367,-121.8926,0,0
        STOP4,Fourth Street,37.3377,-121.8936,0,0
        STOP5,Fifth Street,37.3387,-121.8946,0,0
        """
        try stopsCSV.write(to: gtfsDir.appendingPathComponent("stops.txt"), atomically: true, encoding: .utf8)

        // Create calendar.txt
        let calendarCSV = """
        service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date
        WEEKDAY,1,1,1,1,1,0,0,20240101,20241231
        """
        try calendarCSV.write(to: gtfsDir.appendingPathComponent("calendar.txt"), atomically: true, encoding: .utf8)

        // Create trips.txt
        let tripsCSV = """
        route_id,service_id,trip_id
        ROUTE1,WEEKDAY,TRIP1
        ROUTE1,WEEKDAY,TRIP2
        ROUTE2,WEEKDAY,TRIP3
        """
        try tripsCSV.write(to: gtfsDir.appendingPathComponent("trips.txt"), atomically: true, encoding: .utf8)

        // Create stop_times.txt (all times filled for import testing - interpolation tested separately)
        let stopTimesCSV = """
        trip_id,arrival_time,departure_time,stop_id,stop_sequence
        TRIP1,08:00:00,08:00:00,STOP1,1
        TRIP1,08:05:00,08:05:00,STOP2,2
        TRIP1,08:10:00,08:10:00,STOP3,3
        TRIP1,08:15:00,08:15:00,STOP4,4
        TRIP1,08:20:00,08:20:00,STOP5,5
        TRIP2,09:00:00,09:00:00,STOP1,1
        TRIP2,09:05:00,09:05:00,STOP2,2
        TRIP2,09:10:00,09:10:00,STOP3,3
        TRIP2,09:15:00,09:15:00,STOP4,4
        TRIP2,09:20:00,09:20:00,STOP5,5
        TRIP3,10:00:00,10:00:00,STOP1,1
        TRIP3,10:10:00,10:10:00,STOP3,2
        TRIP3,10:20:00,10:20:00,STOP5,3
        """
        try stopTimesCSV.write(to: gtfsDir.appendingPathComponent("stop_times.txt"), atomically: true, encoding: .utf8)

        // Create empty optional files to prevent import errors
        // calendar_dates.txt (optional - but importer tries to load it)
        let calendarDatesCSV = """
        service_id,date,exception_type
        """
        try calendarDatesCSV.write(to: gtfsDir.appendingPathComponent("calendar_dates.txt"), atomically: true, encoding: .utf8)

        // fare_attributes.txt (optional)
        let fareAttributesCSV = """
        fare_id,price,currency_type
        """
        try fareAttributesCSV.write(to: gtfsDir.appendingPathComponent("fare_attributes.txt"), atomically: true, encoding: .utf8)

        // fare_rules.txt (optional)
        let fareRulesCSV = """
        fare_id,route_id
        """
        try fareRulesCSV.write(to: gtfsDir.appendingPathComponent("fare_rules.txt"), atomically: true, encoding: .utf8)

        // directions.txt (optional - VTA extension)
        let directionsCSV = """
        direction_id,route_id,direction
        """
        try directionsCSV.write(to: gtfsDir.appendingPathComponent("directions.txt"), atomically: true, encoding: .utf8)

        // shapes.txt (optional)
        let shapesCSV = """
        shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence
        """
        try shapesCSV.write(to: gtfsDir.appendingPathComponent("shapes.txt"), atomically: true, encoding: .utf8)

        return gtfsDir
    }
}
