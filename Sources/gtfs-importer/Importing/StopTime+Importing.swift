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

    static func receiveImport(from reader: CSVReader, with db: Database) throws {
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
        } catch {
            Logger.importer.error("Error importing \(Self.self) - \(error)\n\(reader.currentRow ?? [])")
        }
    }

    private static func validatedTime(_ value: String?) throws -> String {
        guard let value, !value.isEmpty else { return "" }
        guard let sanitized = value.sanitizedTimeString,
            let date = DateFormatter.hhmmss.date(from: sanitized),
            let hour = Int(value.prefix(while: { $0 != ":" }))
        else {
            throw ImporterError.invalidTime(time: value)
        }
        // Retain service-day hours until interpolation has finished across midnight.
        let hours = hour < 10 ? "0\(hour)" : String(hour)
        return hours + DateFormatter.hhmmss.string(from: date).suffix(6)
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

    /// The public model stores times of day. Fold extended hours only after
    /// interpolation so a 23:50 -> 24:10 interval remains twenty minutes.
    static func normalizeServiceDayTimes(in db: Database) throws {
        for column in ["arrival_time", "departure_time"] {
            try db.execute(
                sql: """
                    UPDATE stop_times
                    SET \(column) = printf('%02d', CAST(substr(\(column), 1, instr(\(column), ':') - 1) AS INTEGER) % 24)
                        || substr(\(column), instr(\(column), ':'))
                    WHERE CAST(substr(\(column), 1, instr(\(column), ':') - 1) AS INTEGER) >= 24
                    """)
        }
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
