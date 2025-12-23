//
//  ConsoleTests.swift
//  gtfs-importerTests
//
//  Tests for Console color utilities
//

import Foundation
import Testing
@testable import gtfs_importer

@Suite("Console Tests")
struct ConsoleTests {

    @Test("ANSI color codes are correct")
    func testColorCodes() {
        #expect(Console.black == "\u{001B}[0;30m")
        #expect(Console.red == "\u{001B}[0;31m")
        #expect(Console.green == "\u{001B}[0;32m")
        #expect(Console.yellow == "\u{001B}[0;33m")
        #expect(Console.blue == "\u{001B}[0;34m")
        #expect(Console.magenta == "\u{001B}[0;35m")
        #expect(Console.cyan == "\u{001B}[0;36m")
        #expect(Console.white == "\u{001B}[0;37m")
        #expect(Console.resetAttributes == "\u{001B}[0;39m")
    }

    @Test("Color wrapping produces expected format when colors enabled")
    func testColorWrappingFormat() {
        let testString = "Hello"

        // If colors are not disabled, verify proper wrapping
        if !Console.colorsDisabled {
            #expect(Console.green(string: testString) == "\u{001B}[0;32mHello\u{001B}[0;39m")
            #expect(Console.magenta(string: testString) == "\u{001B}[0;35mHello\u{001B}[0;39m")
        }
    }

    @Test("String extension properties match Console methods")
    func testStringExtensions() {
        let testString = "Test"

        #expect(testString.green == Console.green(string: testString))
        #expect(testString.magenta == Console.magenta(string: testString))
        #expect(testString.yellow == Console.yellow(string: testString))
        #expect(testString.red == Console.red(string: testString))
        #expect(testString.blue == Console.blue(string: testString))
        #expect(testString.cyan == Console.cyan(string: testString))
        #expect(testString.white == Console.white(string: testString))
        #expect(testString.black == Console.black(string: testString))
    }
}
