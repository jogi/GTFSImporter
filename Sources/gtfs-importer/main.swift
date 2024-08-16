import ArgumentParser
import GTFSModel

struct GTFSImporter: ParsableCommand {
    @Option(name: .shortAndLong, help: "The path where the GTFS CSV files are")
    var path: String
    
    @Flag(name: .shortAndLong, help: "Should a comma-separated column with routes passing through stops be added. Defaults to false.")
    var addStopRoutes: Bool = false

    func run() throws {
        let databaseHelper = try DatabaseHelper()
        
        print("Importing from \(path)")
        
        let importer = Importer(path: path)
        try importer.importAllFiles()
        
        // Add routes to stops tables
        if addStopRoutes {
            print("Adding routes to stops")
            try StopRoute.addStopRoutes()
        }
        
        // Vacuum
        print("Vacuuming...")
        try databaseHelper.vacuum()
        
        // Reindex
        print("Reindexing...")
        try databaseHelper.reindex()
        
        print("Finished importing ✅")
    }
}

GTFSImporter.main()
