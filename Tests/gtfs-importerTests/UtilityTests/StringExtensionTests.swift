//
//  StringExtensionTests.swift
//  gtfs-importerTests
//
//  Tests for String extension utilities
//

import Foundation
import Testing
@testable import gtfs_importer

@Suite("String Extension Tests")
struct StringExtensionTests {

    @Test("Times less than 24:00:00 have hour preserved (but leading zero removed)", arguments: [
        ("00:00:00", "0:00:00"),
        ("01:30:00", "1:30:00"),
        ("08:15:30", "8:15:30"),
        ("12:45:15", "12:45:15"),
        ("23:59:59", "23:59:59"),
    ])
    func testTimesUnder24Hours(input: String, expected: String) {
        #expect(input.sanitizedTimeString == expected)
    }

    @Test("Times at exactly 24:00:00 become 0:00:00")
    func testMidnightBoundary() {
        #expect("24:00:00".sanitizedTimeString == "0:00:00")
    }

    @Test("Times >= 24:00:00 subtract 24 from hour", arguments: [
        ("24:00:00", "0:00:00"),
        ("25:30:15", "1:30:15"),
        ("26:45:00", "2:45:00"),
        ("27:15:30", "3:15:30"),
        ("28:00:00", "4:00:00"),
    ])
    func testOvernightTimes(input: String, expected: String) {
        #expect(input.sanitizedTimeString == expected)
    }

    @Test("Edge case: 48:00:00 becomes 24:00:00")
    func testExtremeOvernightTime() {
        // This is an extreme case - 48 hours after midnight
        #expect("48:00:00".sanitizedTimeString == "24:00:00")
    }

    @Test("Minutes and seconds are preserved")
    func testMinutesAndSecondsPreserved() {
        #expect("25:30:45".sanitizedTimeString == "1:30:45")
        #expect("24:59:59".sanitizedTimeString == "0:59:59")
    }
}
