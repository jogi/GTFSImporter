//
//  File.swift
//  
//
//  Created by Vashishtha Jogi on 6/14/20.
//

import Foundation
import CSV
import GRDB

enum ImporterError: LocalizedError {
    case invalidStream(path: String)
    
    var errorDescription: String? {
        switch self {
        case let .invalidStream(path):
            return "Cannot create an InputStream for file at path \(path)"
        }
    }
}

protocol ImporterReceiving {
    static func receiveImport(from reader: CSVReader, with db: Database) throws
}

extension ImporterReceiving where Self: Codable, Self: PersistableRecord {
    static func receiveImport(from reader: CSVReader, with db: Database) throws {
        do {
            let record = try CSVRowDecoder().decode(Self.self, from: reader)
            try record.insert(db)
        }
    }
}

protocol ImporterImporting: ImporterReceiving, DatabaseCreating {
    static var fileName: String { get }
    static var dbQueue: DatabaseQueue? { get }
    
    static func importFile(from path: String) throws
}

extension ImporterImporting {
    static func importFile(from path: String) throws {
        print("Importing from \(fileName)")
        
        do {
            let fileURL = URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent(fileName)
            guard let stream = InputStream(url: fileURL) else {
                throw ImporterError.invalidStream(path: fileURL.path)
            }
            
            let startTime = Date()
            
            // First let's cleanup the table
            try self.createTable()
            
            let reader = try CSVReader(stream: stream, hasHeaderRow: true)
            
            var count = 0
            try dbQueue?.write { db in
                while reader.next() != nil {
                    try receiveImport(from: reader, with: db)
                    count += 1
                }
            }
            
            let endTime = Date()

            print(String(format: "Imported \(count) records in %.3f seconds", endTime.timeIntervalSince(startTime)))
        }
    }
}

struct Importer {
    var path: String
    
    func importAllFiles() throws {
        try Agency.importFile(from: path)
        try Calendar.importFile(from: path)
        try CalendarDate.importFile(from: path)
        try FareAttribute.importFile(from: path)
        try FareRule.importFile(from: path)
        try Direction.importFile(from: path)
        try Stop.importFile(from: path)
        try Route.importFile(from: path)
        try Shape.importFile(from: path)
        try StopTime.importFile(from: path)
        try Trip.importFile(from: path)
    }
}

