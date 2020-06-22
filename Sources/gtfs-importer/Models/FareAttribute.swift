//
//  FareAttribute.swift
//  
//
//  Created by Vashishtha Jogi on 6/20/20.
//

import Foundation
import GRDB

struct FareAttribute {
    enum PaymentMethod: Int, Codable {
        case paidOnBoard = 0
        case paidBeforeBoarding = 1
    }
    enum AllowedTransfers: Int, Codable {
        case no = 0
        case once = 1
        case twice = 2
        case unlimited = -1
    }
    var identifier: String
    var price: Float
    var currencyType: String
    var paymentMethod: PaymentMethod
    var transfers: AllowedTransfers = .unlimited
    var agencyIdentifier: String?
    var transferDuration: UInt?
}

// For diffing
extension FareAttribute: Hashable {}

extension FareAttribute: Codable, PersistableRecord {
    static var databaseTableName = "fare_attributes"
    
    private enum Columns {
        static let identifier = Column(CodingKeys.identifier)
        static let price = Column(CodingKeys.price)
        static let currencyType = Column(CodingKeys.currencyType)
        static let paymentMethod = Column(CodingKeys.paymentMethod)
        static let transfers = Column(CodingKeys.transfers)
        static let agencyIdentifier = Column(CodingKeys.agencyIdentifier)
        static let transferDuration = Column(CodingKeys.transferDuration)
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier = "fare_id"
        case price
        case currencyType = "currency_type"
        case paymentMethod = "payment_method"
        case transfers
        case agencyIdentifier = "agency_id"
        case transferDuration = "transfer_duration"
    }
}

extension FareAttribute: CustomStringConvertible {
    var description: String {
        return "\(identifier): \(price) - \(currencyType)"
    }
}
