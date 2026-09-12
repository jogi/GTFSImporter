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
    @Test("File summaries count rejections while retaining later valid rows")
    func summary() throws {
        let directory = try TestDataHelper.createMinimalGTFSDataset()
        defer { TemporaryFileHelper.cleanup(directory: directory) }
        try """
            agency_id,agency_name,agency_url,agency_timezone
            A,Original,https://example.com,America/Los_Angeles
            A,Duplicate,https://example.com,America/Los_Angeles
            B,Later,https://example.com,America/Los_Angeles
            """.write(to: directory.appendingPathComponent("agency.txt"), atomically: true, encoding: .utf8)
        let queue = try DatabaseQueue()
        defer { try? queue.close() }
        try queue.write { db in
            let summary = try Agency.importFile(from: directory.path, into: db)
            #expect(summary == FileImportSummary(fileName: "agency.txt", accepted: 2, rejected: 1))
            #expect(try Agency.fetchCount(db) == 2)
        }
    }
}
