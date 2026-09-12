//
//  Route+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import CSV
import GRDB
import GTFSModel
import OSLog

extension Route: ImporterImporting {
    static var fileName: String {
        return "routes.txt"
    }
    
    @discardableResult
    static func receiveImport(from reader: CSVReader, with db: Database) throws -> Bool {
        do {
            let decoder = CSVRowDecoder()
            var record = try decoder.decode(Self.self, from: reader)
            record.color = record.color ?? "FFFFFF"
            record.textColor = record.textColor ?? "000000"
            record.sortOrder = record.sortOrder ?? 0
            record.continuousPickup = record.continuousPickup ?? .notContinuous
            record.continuousDropoff = record.continuousDropoff ?? .notContinuous
            try record.insert(db)
            return true
        } catch {
            ImportDiagnostics.rejected(Self.self, error: error, row: reader.currentRow)
            return false
        }
    }
}
