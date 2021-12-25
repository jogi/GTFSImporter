//
//  StopTime.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import GRDB

struct StopTime {
    enum PickupDropoffMethod: Int, Codable {
        case regularlyScheduled = 0
        case notAvailable = 1
        case phoneAgency = 2
        case coordinateWithDriver = 3
    }
    
    enum ContinuationType: Int, Codable {
        case continuous = 0
        case notContinuous = 1
        case phoneAgencyToArrange = 2
        case coordinateWithDriver = 3
    }
    
    enum TimepointType: Int, Codable {
        case approximate = 0
        case exact = 1
    }
    
    var tripIdentifier: String
    var arrivalTime: Date
    var departureTime: Date
    var stopIdentifier: String
    var stopSequence: UInt
    var stopHeadsign: String?
    var pickupType: PickupDropoffMethod?
    var dropoffType: PickupDropoffMethod?
    var continuousPickup: ContinuationType?
    var continuousDropoff: ContinuationType?
    var shapeDistanceTraveled: Double?
    var timepoint: TimepointType?
}

// For diffing
extension StopTime: Hashable {}

extension StopTime: Codable, PersistableRecord {
    static var databaseTableName = "stop_times"
    static var databaseDateEncodingStrategy = DatabaseDateEncodingStrategy.formatted(DateFormatter.hhmmss)
    
    private enum Columns {
        static let tripIdentifier = Column(CodingKeys.tripIdentifier)
        static let arrivalTime = Column(CodingKeys.arrivalTime)
        static let departureTime = Column(CodingKeys.departureTime)
        static let stopIdentifier = Column(CodingKeys.stopIdentifier)
        static let stopSequence = Column(CodingKeys.stopSequence)
        static let stopHeadsign = Column(CodingKeys.stopHeadsign)
        static let pickupType = Column(CodingKeys.pickupType)
        static let dropoffType = Column(CodingKeys.dropoffType)
        static let continuousPickup = Column(CodingKeys.continuousPickup)
        static let continuousDropoff = Column(CodingKeys.continuousDropoff)
        static let shapeDistanceTraveled = Column(CodingKeys.shapeDistanceTraveled)
        static let timepoint = Column(CodingKeys.timepoint)
    }
    
    enum CodingKeys: String, CodingKey {
        case tripIdentifier = "trip_id"
        case arrivalTime = "arrival_time"
        case departureTime = "departure_time"
        case stopIdentifier = "stop_id"
        case stopSequence = "stop_sequence"
        case stopHeadsign = "stop_headsign"
        case pickupType = "pickup_type"
        case dropoffType = "drop_off_type"
        case continuousPickup = "continuous_pickup"
        case continuousDropoff = "continuous_drop_off"
        case shapeDistanceTraveled = "shape_dist_traveled"
        case timepoint = "timepoint"
    }
}

extension StopTime: CustomStringConvertible {
    var description: String {
        return "\(tripIdentifier): \(stopSequence), \(arrivalTime) - \(departureTime)"
    }
}
