//
//  File.swift
//  
//
//  Created by Vashishtha Jogi on 6/14/20.
//

import Foundation
import CSV
import GRDB

struct Calendar {
    var serviceIdentifier: String
    var startDate: String
    var endDate: String
    var monday: Int
    var tuesday: Int
    var wednesday: Int
    var thursday: Int
    var friday: Int
    var saturday: Int
    var sunday: Int
}

// For diffing
extension Calendar: Hashable {}

extension Calendar: Codable, PersistableRecord {
    private enum Columns {
        static let serviceIdentifier = Column(CodingKeys.serviceIdentifier)
        static let startDate = Column(CodingKeys.startDate)
        static let endDate = Column(CodingKeys.endDate)
        static let monday = Column(CodingKeys.monday)
        static let tuesday = Column(CodingKeys.tuesday)
        static let wednesday = Column(CodingKeys.wednesday)
        static let thursday = Column(CodingKeys.thursday)
        static let friday = Column(CodingKeys.friday)
        static let saturday = Column(CodingKeys.saturday)
        static let sunday = Column(CodingKeys.sunday)
    }
    
    enum CodingKeys: String, CodingKey {
        case serviceIdentifier = "service_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
        case sunday
    }
}

extension Calendar: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "calendar.txt"
    }
    
    static var dbQueue: DatabaseQueue? {
        return try? DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    // MARK:- DatabaseCreating
    static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: "calendar")
            } catch {
                print("Table calendar does not exist.")
            }
            
            // now create new table
            try db.create(table: "calendar") { t in
                t.column("service_id", .text).notNull().indexed()
                t.column("start_date", .text).notNull()
                t.column("end_date", .text).notNull()
                t.column("monday", .integer).notNull()
                t.column("tuesday", .integer).notNull()
                t.column("wednesday", .integer).notNull()
                t.column("thursday", .integer).notNull()
                t.column("friday", .integer).notNull()
                t.column("saturday", .integer).notNull()
                t.column("sunday", .integer).notNull()
            }
        }
    }
}

extension Calendar: CustomStringConvertible {
    var description: String {
        return "\(serviceIdentifier): \(startDate) - \(endDate)"
    }
}
