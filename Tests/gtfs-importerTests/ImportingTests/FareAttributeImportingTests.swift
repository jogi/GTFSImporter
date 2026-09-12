import CSV
import GRDB
import GTFSModel
import Testing

@testable import gtfs_importer

struct FareAttributeImportingTests {
    @Test("Empty transfers mean unlimited, while explicit limits are preserved")
    func transfers() throws {
        let queue = try DatabaseQueue()
        defer { try? queue.close() }
        try queue.write { db in
            try FareAttribute.createTable(db: db)
            try ImportTestSupport.receive(FareAttribute.self, csv: """
                fare_id,price,currency_type,payment_method,transfers,transfer_duration
                unlimited,2.50,USD,0,,7200
                none,5.00,USD,1,0,
                once,2.50,USD,0,1,7200
                twice,2.50,USD,0,2,7200
                invalid,2.50,USD,0,3,7200
                later,0.00,USD,0,0,
                """, in: db)
            #expect(try String.fetchAll(db, sql: "SELECT fare_id FROM fare_attributes ORDER BY rowid") == ["unlimited", "none", "once", "twice", "later"])
            #expect(try Int.fetchAll(db, sql: "SELECT transfers FROM fare_attributes ORDER BY rowid") == [-1, 0, 1, 2, 0])
            let unlimited = try #require(try FareAttribute.fetchOne(db, key: "unlimited"))
            #expect(unlimited.transfers == .unlimited)
            #expect(unlimited.transferDuration == 7200)
        }
    }
}
