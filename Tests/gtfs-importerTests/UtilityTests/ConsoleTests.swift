import Testing

@testable import gtfs_importer

struct ConsoleTests {
    @Test("Color formatting is independent of the runner's terminal", arguments: [false, true])
    func wrapping(disabled: Bool) {
        #expect(
            Console.wrap(colorCode: Console.green, string: "Hello", colorsDisabled: disabled)
                == (disabled ? "Hello" : "\u{001B}[0;32mHello\u{001B}[0;39m"))
    }
}
