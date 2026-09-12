import Foundation
import GRDB
import GTFSModel
import Testing

@testable import gtfs_importer

struct EndToEndImportTests {
    @Test("Command workflow interpolates times and honors the route option", arguments: [false, true], [false, true])
    func workflow(addRoutes: Bool, overnight: Bool) throws {
        let directory = try TestDataHelper.createMinimalGTFSDataset()
        defer { TemporaryFileHelper.cleanup(directory: directory) }
        if overnight {
            try
                "trip_id,stop_id,stop_sequence,arrival_time,departure_time\nT,A,1,23:50:00,23:51:00\nT,B,2,,\nT,C,3,24:10:00,24:11:00"
                .write(to: directory.appendingPathComponent("stop_times.txt"), atomically: true, encoding: .utf8)
        }
        let database = try DatabaseQueue(path: directory.appendingPathComponent("output.db").path)
        defer { try? database.close() }
        let arguments = ["--path", directory.path] + (addRoutes ? ["--add-stop-routes"] : [])
        let command = try GTFSImporter.parse(arguments)
        try command.run(database: database)
        try database.read { (db: Database) throws -> Void in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM stop_times ORDER BY stop_sequence")
            #expect(
                rows.map { $0["arrival_time"] as String }
                    == (overnight ? ["23:50:00", "23:55:00", "00:10:00"] : ["08:00:00", "08:05:00", "08:20:00"]))
            #expect(
                rows.map { $0["departure_time"] as String }
                    == (overnight ? ["23:51:00", "23:55:00", "00:11:00"] : ["08:01:00", "08:05:00", "08:21:00"]))
            #expect(rows.map { $0["timepoint"] as Int } == [1, 0, 1])
            #expect(rows.map { $0["is_laststop"] as Bool } == [false, false, true])
            let routes = try Stop.fetchAll(db).map(\.routes)
            #expect(routes == Array(repeating: addRoutes ? "Red" : nil, count: 3))
        }
    }

    @Test("The small VTA feed imports every supported entity")
    func realFeed() throws {
        let database = try DatabaseQueue()
        defer { try? database.close() }
        try Importer(path: TestDataHelper.smallRealTestDataPath(), database: database).importAllFiles()
        try database.read { (db: Database) throws -> Void in
            let tables = [
                "agency", "routes", "stops", "calendar", "calendar_dates", "fare_attributes", "fare_rules",
                "directions", "shapes", "trips", "stop_times",
            ]
            let counts = try tables.map { try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \($0)") }
            #expect(counts == [1, 1, 26, 3, 30, 3, 1, 2, 958, 5, 130].map(Optional.some))
            #expect(try Row.fetchAll(db, sql: "PRAGMA foreign_key_check").isEmpty)
        }
    }

    @Test("Absent and header-only optional files produce empty tables", arguments: [false, true])
    func optionalFiles(headerOnly: Bool) throws {
        let directory = try TestDataHelper.createMinimalGTFSDataset()
        defer { TemporaryFileHelper.cleanup(directory: directory) }
        let optional = [
            ("calendar_dates", "service_id,date,exception_type"),
            ("fare_attributes", "fare_id,price,currency_type,payment_method,transfers"),
            ("fare_rules", "fare_id,route_id"),
            ("directions", "route_id,direction_id,direction"),
            ("shapes", "shape_id,shape_pt_lat,shape_pt_lon,shape_pt_sequence"),
        ]
        if headerOnly {
            for (name, header) in optional {
                try (header + "\n").write(
                    to: directory.appendingPathComponent(name + ".txt"), atomically: true, encoding: .utf8)
            }
        }
        let database = try DatabaseQueue()
        defer { try? database.close() }
        try Importer(path: directory.path, database: database).importAllFiles()
        try database.read { (db: Database) throws -> Void in
            #expect(try StopTime.fetchCount(db) == 3)
            for (name, _) in optional {
                #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(name)") == 0)
            }
        }
    }

    @Test("An unavailable required file aborts replacement and preserves the old feed", arguments: [false, true])
    func unavailableRequiredFile(directoryInstead: Bool) throws {
        let directory = try TestDataHelper.createMinimalGTFSDataset()
        defer { TemporaryFileHelper.cleanup(directory: directory) }
        let database = try DatabaseQueue()
        defer { try? database.close() }
        let importer = Importer(path: directory.path, database: database)
        try importer.importAllFiles()
        try database.write { try $0.execute(sql: "UPDATE agency SET agency_name = 'Previous feed'") }
        let missingFile = directory.appendingPathComponent("stop_times.txt")
        try FileManager.default.removeItem(at: missingFile)
        if directoryInstead {
            try FileManager.default.createDirectory(at: missingFile, withIntermediateDirectories: false)
        }
        #expect(throws: ImporterError.invalidStream(path: missingFile.path)) {
            try importer.importAllFiles()
        }
        try database.read { (db: Database) throws -> Void in
            #expect(try String.fetchOne(db, sql: "SELECT agency_name FROM agency") == "Previous feed")
            #expect(try StopTime.fetchCount(db) == 3)
        }
    }

    @Test("A second import replaces records without duplicates or stale rows")
    func replacement() throws {
        let directory = try TestDataHelper.createMinimalGTFSDataset()
        defer { TemporaryFileHelper.cleanup(directory: directory) }
        let database = try DatabaseQueue()
        defer { try? database.close() }
        let importer = Importer(path: directory.path, database: database)
        try importer.importAllFiles()
        try "trip_id,stop_id,stop_sequence,arrival_time,departure_time\nT,C,10,09:00:00,09:00:00"
            .write(to: directory.appendingPathComponent("stop_times.txt"), atomically: true, encoding: .utf8)
        try importer.importAllFiles()
        try database.read { (db: Database) throws -> Void in
            #expect(try StopTime.fetchCount(db) == 1)
            let stop = try #require(try StopTime.fetchOne(db))
            #expect(stop.stopIdentifier == "C")
            #expect(stop.stopSequence == 10)
            #expect(stop.isLastStop == true)
        }
    }
}
