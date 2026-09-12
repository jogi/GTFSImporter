import ArgumentParser
import Foundation
import GRDB

@main
struct GTFSImporter: ParsableCommand {
    @Option(name: .shortAndLong, help: "The path where the GTFS CSV files are")
    var path: String

    @Flag(
        name: .shortAndLong,
        help: "Should a comma-separated column with routes passing through stops be added. Defaults to false.")
    var addStopRoutes: Bool = false

    func run() throws {
        let startTime = Date()

        let database = try DatabaseQueue(path: "./\(Importer.defaultDatabaseFileName)")
        defer { try? database.close() }
        try run(database: database)

        let endTime = Date()
        let duration = String(format: "%.2f", endTime.timeIntervalSince(startTime))

        print("\n✅ Finished importing in \(duration.green) seconds")
    }

    func run(database: DatabaseQueue) throws {
        try Importer(path: path, database: database).run(addStopRoutes: addStopRoutes)
    }
}
