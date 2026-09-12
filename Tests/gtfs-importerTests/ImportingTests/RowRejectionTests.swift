import GRDB
import GTFSModel
import Testing

@testable import gtfs_importer

struct RowRejectionTests {
    @Test("Shared receiver skips duplicate keys and malformed rows, then continues")
    func rejectedRows() throws {
        let queue = try ImportTestSupport.database()
        defer { try? queue.close() }
        try queue.write { (db: Database) throws -> Void in
            try ImportTestSupport.receive(
                Agency.self,
                csv: """
                    agency_id,agency_name,agency_url,agency_timezone
                    A,Original,https://example.com,America/Los_Angeles
                    A,Duplicate,https://example.com,America/Los_Angeles
                    BAD
                    B,Later,https://example.com,America/Los_Angeles
                    """, in: db)
            #expect(
                try String.fetchAll(db, sql: "SELECT agency_name FROM agency ORDER BY agency_id") == [
                    "Original", "Later",
                ])
        }
    }
}
