import GRDB
import Testing

@testable import gtfs_importer

struct StopRouteTests {
    @Test("Route aggregation includes every trip, deduplicates names, and clears stale routes")
    func aggregation() throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            // T and U share the attributes used by the old grouping query but visit different stops.
            try db.execute(
                sql: """
                    INSERT INTO routes (route_id, route_type, route_short_name) VALUES ('G',3,'Green'), ('N',3,NULL);
                    INSERT INTO trips (trip_id, route_id, service_id) VALUES ('U','R','S'), ('V','G','S'), ('W','N','S');
                    INSERT INTO stop_times (trip_id,stop_id,stop_sequence,arrival_time,departure_time) VALUES
                    ('T','A',1,'08:00:00','08:00:00'), ('T','A',2,'08:01:00','08:01:00'),
                    ('U','B',1,'08:00:00','08:00:00'), ('V','A',1,'08:00:00','08:00:00'),
                    ('W','A',1,'08:00:00','08:00:00');
                    UPDATE stops SET routes = 'Stale';
                    """)
            try StopRoute.addStopRoutes(in: db)
            #expect(try String.fetchOne(db, sql: "SELECT routes FROM stops WHERE stop_id='A'") == "Green, Red")
            #expect(try String.fetchOne(db, sql: "SELECT routes FROM stops WHERE stop_id='B'") == "Red")
            #expect(try String.fetchOne(db, sql: "SELECT routes FROM stops WHERE stop_id='C'") == nil)
            try db.execute(sql: "DELETE FROM stop_times")
            try StopRoute.addStopRoutes(in: db)
            #expect(try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM stops WHERE routes IS NOT NULL") == 0)
        }
    }
}
