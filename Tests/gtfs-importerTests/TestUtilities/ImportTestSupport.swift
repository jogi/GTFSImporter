import CSV
import GRDB
import GTFSModel

@testable import gtfs_importer

enum ImportTestSupport {
    static func database() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try queue.write { (db: Database) throws -> Void in
            try Agency.createTable(db: db)
            try GTFSModel.Calendar.createTable(db: db)
            try CalendarDate.createTable(db: db)
            try Route.createTable(db: db)
            try Trip.createTable(db: db)
            try Stop.createTable(db: db)
            try StopTime.createTable(db: db)
            try db.execute(sql: "INSERT INTO routes (route_id, route_type, route_short_name) VALUES ('R', 3, 'Red')")
            try db.execute(sql: "INSERT INTO trips (trip_id, route_id, service_id) VALUES ('T', 'R', 'S')")
            try db.execute(
                sql: """
                    INSERT INTO stops (stop_id, stop_lat, stop_lon, location_type, wheelchair_boarding)
                    VALUES ('A', 0, 0, 0, 0), ('B', 1, 0, 0, 0), ('C', 4, 0, 0, 0)
                    """)
        }
        return queue
    }

    static func receive<T: ImporterReceiving>(_ type: T.Type, csv: String, in db: Database) throws {
        let reader = try CSVReader(string: csv, hasHeaderRow: true)
        while reader.next() != nil { try T.receiveImport(from: reader, with: db) }
    }
}
