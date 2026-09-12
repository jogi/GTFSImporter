//
//  CalendarDates+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import CSV
import GRDB
import GTFSModel
import OSLog

extension CalendarDate: ImporterImporting {
    static var fileName: String {
        return "calendar_dates.txt"
    }
    
    @discardableResult
    static func receiveImport(from reader: CSVReader, with db: Database) throws -> Bool {
        do {
            let decoder = CSVRowDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.yyyyMMdd)
            let record = try decoder.decode(Self.self, from: reader)
            try record.insert(db)
            return true
        } catch {
            ImportDiagnostics.rejected(Self.self, error: error, row: reader.currentRow)
            return false
        }
    }
}
