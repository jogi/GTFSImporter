import Testing

@testable import gtfs_importer

struct StringExtensionTests {
    @Test(
        "Service-day hours normalize to a time of day",
        arguments: [
            ("00:00:00", "0:00:00"), ("08:15:30", "8:15:30"),
            ("23:59:59", "23:59:59"), ("24:00:00", "0:00:00"),
            ("25:30:45", "1:30:45"), ("48:00:00", "0:00:00"),
        ])
    func normalization(input: String, expected: String) {
        #expect(input.sanitizedTimeString == expected)
    }

    @Test(
        "Malformed times are rejected",
        arguments: ["", "x:00:00", "12:30", "12:60:00", "12:30:60", "-1:00:00", "12:00:00:00"])
    func malformed(input: String) {
        #expect(input.sanitizedTimeString == nil)
    }
}
