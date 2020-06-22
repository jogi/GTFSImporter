//
//  Calendar.swift
//  
//
//  Created by Vashishtha Jogi on 6/14/20.
//

import Foundation
import CSV
import GRDB

struct Calendar {
    enum Availability: Int, Codable {
        case unavailable = 0
        case available = 1
    }
    var serviceIdentifier: String
    var startDate: Date
    var endDate: Date
    var monday: Availability
    var tuesday: Availability
    var wednesday: Availability
    var thursday: Availability
    var friday: Availability
    var saturday: Availability
    var sunday: Availability
}

// For diffing
extension Calendar: Hashable {}

extension Calendar: Codable, PersistableRecord {
    static let databaseDateEncodingStrategy: DatabaseDateEncodingStrategy = .formatted(DateFormatter.yyyyMMddDash)
    
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

extension Calendar: CustomStringConvertible {
    var description: String {
        return "\(serviceIdentifier): \(startDate) - \(endDate)"
    }
}
