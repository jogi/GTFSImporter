//
//  CalendarDate.swift
//  
//
//  Created by Vashishtha Jogi on 6/20/20.
//

import Foundation
import CSV
import GRDB

struct CalendarDate {
    enum ExceptionType: Int, Codable {
        case added = 1
        case removed = 2
    }
    var serviceIdentifier: String
    var date: Date
    var exceptionType: ExceptionType
}

// For diffing
extension CalendarDate: Hashable {}

extension CalendarDate: Codable, PersistableRecord {
    static let databaseDateEncodingStrategy: DatabaseDateEncodingStrategy = .formatted(DateFormatter.yyyyMMddDash)
    static var databaseTableName = "calendar_dates"
    
    private enum Columns {
        static let serviceIdentifier = Column(CodingKeys.serviceIdentifier)
        static let date = Column(CodingKeys.date)
        static let exceptionType = Column(CodingKeys.exceptionType)
    }
    
    enum CodingKeys: String, CodingKey {
        case serviceIdentifier = "service_id"
        case date = "date"
        case exceptionType = "exception_type"
    }
}

extension CalendarDate: CustomStringConvertible {
    var description: String {
        return "\(serviceIdentifier): \(date) - \(exceptionType)"
    }
}
