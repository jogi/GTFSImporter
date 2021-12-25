import ArgumentParser
import GTFSModel

struct GTFSImporter: ParsableCommand {
    @Option(name: .shortAndLong, help: "The path where the GTFS CSV files are")
    var path: String

    func run() throws {
        let databaseHelper = try DatabaseHelper()
        
        print("Importing from \(path)")
        
        let importer = Importer(path: path)
        try importer.importAllFiles()
        
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
