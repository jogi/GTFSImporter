//
//  FareAttributes.swift
//  
//
//  Created by Vashishtha Jogi on 6/20/20.
//

import Foundation
import CSV
import GRDB

struct FareAttributes {
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
    var transfers: AllowedTransfers
    var agencyIdentifier: String?
    var transferDuration: UInt?
}

// For diffing
extension FareAttributes: Hashable {}

extension FareAttributes: Codable, PersistableRecord {
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

extension FareAttributes: ImporterImporting {
    // MARK: - ImporterImporting
    static var fileName: String {
        return "fare_attributes.txt"
    }
    
    static var dbQueue: DatabaseQueue? {
        return try? DatabaseQueue(path: "./gtfs.sqlite")
    }
    
    // MARK:- DatabaseCreating
    static func createTable() throws {
        try dbQueue?.write { db in
            do {
                try db.drop(table: "fare_attributes")
            } catch {
                print("Table fare_attributes does not exist.")
            }
            
            // now create new table
            try db.create(table: "fare_attributes") { t in
                t.column("fare_id", .text).notNull().indexed()
                t.column("price", .double).notNull()
                t.column("currency_type", .text).notNull()
                t.column("payment_method", .integer).notNull()
                t.column("transfers", .integer).notNull().defaults(to: -1)
                t.column("agency_id", .text)
                t.column("transfer_duration", .integer)
            }
        }
    }
}

extension FareAttributes: CustomStringConvertible {
    var description: String {
        return "\(identifier): \(price) - \(currencyType)"
    }
}
