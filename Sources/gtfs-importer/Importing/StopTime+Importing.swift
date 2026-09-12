//
//  StopTime+Importing.swift
//
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import CSV
import Foundation
import GRDB
import GTFSModel
import OSLog

extension StopTime: ImporterImporting {
    static var fileName: String {
        return "stop_times.txt"
    }

    @discardableResult
    static func receiveImport(from reader: CSVReader, with db: Database) throws -> Bool {
        do {
            var record = try CSVRowDecoder().decode(ImportRecord.self, from: reader)
            record.arrivalTime = try validatedTime(record.arrivalTime)
            record.departureTime = try validatedTime(record.departureTime)

            record.pickupType = record.pickupType ?? .regularlyScheduled
            record.dropoffType = record.dropoffType ?? .regularlyScheduled
            record.continuousPickup = record.continuousPickup ?? .notContinuous
            record.continuousDropoff = record.continuousDropoff ?? .notContinuous
            record.timepoint = record.timepoint ?? .exact
            record.isLastStop = false
            try record.insert(db)
            return true
        } catch {
            ImportDiagnostics.rejected(Self.self, error: error, row: reader.currentRow)
            return false
        }
    }

    private static func validatedTime(_ value: String?) throws -> String {
        guard let value, !value.isEmpty else { return "" }
        guard let date = ServiceDayTime.date(from: value),
            let normalized = ServiceDayTime.string(from: date)
        else { throw ImporterError.invalidTime(time: value) }
        return normalized
    }

    // A GTFS row may be untimed until interpolation. Keep that staging state
    // separate from the public model, whose arrival/departure Dates are required.
    private struct ImportRecord: Codable, PersistableRecord {
        static let databaseTableName = StopTime.databaseTableName
        typealias CodingKeys = StopTime.CodingKeys

        var tripIdentifier: String
        var arrivalTime: String?
        var departureTime: String?
        var stopIdentifier: String
        var stopSequence: UInt
        var stopHeadsign: String?
        var pickupType: PickupDropoffMethod?
        var dropoffType: PickupDropoffMethod?
        var continuousPickup: ContinuationType?
        var continuousDropoff: ContinuationType?
        var shapeDistanceTraveled: Double?
        var timepoint: TimepointType?
        var isLastStop: Bool?
    }

    static func updateLastStop(in db: Database) throws {
        try db.execute(
            sql: """
                UPDATE stop_times
                SET is_laststop = ((trip_id, stop_sequence) IN (
                    SELECT trip_id, MAX(stop_sequence) FROM stop_times GROUP BY trip_id
                ))
                """)
    }
}
