import Testing

@testable import gtfs_importer

struct ConsoleTests {
    @Test(
        "Color requires a terminal and no explicit opt-out",
        arguments: [
            (nil as String?, false, true),
            (nil as String?, true, false),
            ("", true, true),
            ("0", true, true),
            ("1", true, true),
            ("", false, true),
        ])
    func colorPolicy(noColorValue: String?, isTerminal: Bool, expectedDisabled: Bool) {
        #expect(Console.shouldDisableColors(noColorValue: noColorValue, isTerminal: isTerminal) == expectedDisabled)
    }

    struct Style: Sendable, CustomTestStringConvertible {
        let name: String
        let foreground: Int
        let apply: @Sendable (String, Bool) -> String
        var testDescription: String { name }
    }

    @Test(
        "Named colors select the correct foreground and honor opt-out",
        arguments: [
            Style(name: "black", foreground: 30, apply: { Console.black(string: $0, colorsDisabled: $1) }),
            Style(name: "red", foreground: 31, apply: { Console.red(string: $0, colorsDisabled: $1) }),
            Style(name: "green", foreground: 32, apply: { Console.green(string: $0, colorsDisabled: $1) }),
            Style(name: "yellow", foreground: 33, apply: { Console.yellow(string: $0, colorsDisabled: $1) }),
            Style(name: "blue", foreground: 34, apply: { Console.blue(string: $0, colorsDisabled: $1) }),
            Style(name: "magenta", foreground: 35, apply: { Console.magenta(string: $0, colorsDisabled: $1) }),
            Style(name: "cyan", foreground: 36, apply: { Console.cyan(string: $0, colorsDisabled: $1) }),
            Style(name: "white", foreground: 37, apply: { Console.white(string: $0, colorsDisabled: $1) }),
        ], [false, true])
    func namedColors(style: Style, disabled: Bool) {
        let expected = disabled ? "Transit" : "\u{001B}[0;\(style.foreground)mTransit\u{001B}[0;39m"
        #expect(style.apply("Transit", disabled) == expected)
    }

    @Test(
        "Wrapping preserves empty, Unicode, multiline, and already-styled text",
        arguments: [
            "", "🚆 Café\nLine 2", "before\u{001B}[1mafter",
        ], [false, true])
    func preservesContent(text: String, disabled: Bool) {
        let expected = disabled ? text : "\u{001B}[0;32m\(text)\u{001B}[0;39m"
        #expect(Console.green(string: text, colorsDisabled: disabled) == expected)
    }
}
