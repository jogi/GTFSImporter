import Foundation
import ArgumentParser
import GTFSModel

struct GTFSImporter: ParsableCommand {
    @Option(name: .shortAndLong, help: "The path where the GTFS CSV files are")
    var path: String
    
    @Flag(name: .shortAndLong, help: "Should a comma-separated column with routes passing through stops be added. Defaults to false.")
    var addStopRoutes: Bool = false

    func run() throws {
        let startTime = Date()

        let databaseHelper = try GTFSModel.DatabaseHelper(path: "./\(Importer.defaultDatabaseFileName)")

        print("Importing from \(path.yellow)\n")

        let importer = Importer(path: path)
        try importer.importAllFiles()

        // Add routes to stops tables
        if addStopRoutes {
            print("Adding routes to stops")
            try StopRoute.addStopRoutes()
        }

        // Vacuum
        print("\n🧹 Vacuuming...")
        try databaseHelper.vacuum()

        // Reindex
        print("🗂️  Reindexing...")
        try databaseHelper.reindex()

        // Interpolate stop times
        print("\n⏱️  Interpolating stop times...")
        try databaseHelper.dbQueue?.write { db in
            try StopTimeInterpolator.interpolateStopTimes(in: db)
        }
        
        let endTime = Date()
        let duration = String(format: "%.2f", endTime.timeIntervalSince(startTime))
        
        print("\n✅ Finished importing in \(duration.green) seconds")
    }
}

GTFSImporter.main()
