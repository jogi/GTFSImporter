import GRDB
import GTFSModel
import Testing

@testable import gtfs_importer

struct CalendarImportingTests {
    @Test("Calendar CSV dates use the model's persisted date format")
    func dates() throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try ImportTestSupport.receive(
                GTFSModel.Calendar.self,
                csv: """
                    service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date
                    S,1,0,1,0,1,0,1,20240229,20241231
                    """, in: db)
            #expect(
                try String.fetchOne(db, sql: "SELECT start_date || '/' || end_date FROM calendar")
                    == "2024-02-29/2024-12-31")
            let calendar = try #require(try GTFSModel.Calendar.fetchOne(db))
            #expect(
                [
                    calendar.monday, calendar.tuesday, calendar.wednesday, calendar.thursday,
                    calendar.friday, calendar.saturday, calendar.sunday,
                ].map(\.rawValue) == [1, 0, 1, 0, 1, 0, 1])
        }
    }

    @Test("Calendar exceptions preserve dates and exception types")
    func exceptions() throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try ImportTestSupport.receive(
                CalendarDate.self,
                csv: """
                    service_id,date,exception_type
                    S,20240229,1
                    S,20241231,2
                    """, in: db)
            #expect(
                try String.fetchAll(db, sql: "SELECT date || ':' || exception_type FROM calendar_dates ORDER BY date")
                    == ["2024-02-29:1", "2024-12-31:2"])
        }
    }

    @Test("Invalid dates are skipped and later rows still import", arguments: [false, true])
    func invalidDates(exceptions: Bool) throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            if exceptions {
                try ImportTestSupport.receive(
                    CalendarDate.self, csv: "service_id,date,exception_type\nBAD,invalid,1\nOK,20240101,2", in: db)
                #expect(try String.fetchAll(db, sql: "SELECT service_id FROM calendar_dates") == ["OK"])
            } else {
                try ImportTestSupport.receive(
                    GTFSModel.Calendar.self,
                    csv:
                        "service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date\nBAD,1,1,1,1,1,0,0,invalid,20241231\nOK,1,1,1,1,1,0,0,20240101,20241231",
                    in: db)
                #expect(try String.fetchAll(db, sql: "SELECT service_id FROM calendar") == ["OK"])
            }
        }
    }
}
