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
        let summaries = try run(database: database)

        let endTime = Date()
        let duration = String(format: "%.2f", endTime.timeIntervalSince(startTime))

        let accepted = summaries.reduce(0) { $0 + $1.accepted }
        let rejected = summaries.reduce(0) { $0 + $1.rejected }
        for summary in summaries where summary.rejected > 0 {
            let message = "\(summary.fileName): \(summary.accepted) imported, \(summary.rejected) rejected\n"
            FileHandle.standardError.write(Data(message.utf8))
        }
        let status = rejected == 0 ? "✅ Finished importing" : "⚠️ Finished importing with row errors"
        print("\n\(status) in \(duration.green) seconds: \(accepted) imported, \(rejected) rejected")
    }

    @discardableResult
    func run(database: DatabaseQueue) throws -> [FileImportSummary] {
        try Importer(path: path, database: database).run(addStopRoutes: addStopRoutes)
    }
}
