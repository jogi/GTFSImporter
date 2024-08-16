//
//  Console.swift
//  
//
//  Created by Vashishtha Jogi on 8/16/24.
//

import Foundation

struct Console {
    public static let resetAttributes = "\u{001B}[0;39m"

    public static let black = "\u{001B}[0;30m"
    public static let red = "\u{001B}[0;31m"
    public static let green = "\u{001B}[0;32m"
    public static let yellow = "\u{001B}[0;33m"
    public static let blue = "\u{001B}[0;34m"
    public static let magenta = "\u{001B}[0;35m"
    public static let cyan = "\u{001B}[0;36m"
    public static let white = "\u{001B}[0;37m"

    public static func black(string: String) -> String {
        return wrap(colorCode: Console.black, string: string)
    }

    public static func red(string: String) -> String {
        return wrap(colorCode: Console.red, string: string)
    }

    public static func green(string: String) -> String {
        return wrap(colorCode: Console.green, string: string)
    }

    public static func yellow(string: String) -> String {
        return wrap(colorCode: Console.yellow, string: string)
    }

    public static func blue(string: String) -> String {
        return wrap(colorCode: Console.blue, string: string)
    }

    public static func magenta(string: String) -> String {
        return wrap(colorCode: Console.magenta, string: string)
    }

    public static func cyan(string: String) -> String {
        return wrap(colorCode: Console.cyan, string: string)
    }

    public static func white(string: String) -> String {
        return wrap(colorCode: Console.white, string: string)
    }

    private static func wrap(colorCode: String, string: String) -> String {
        if Console.colorsDisabled {
            return string
        }

        return colorCode + string + Console.resetAttributes
    }

    public static let colorsDisabled: Bool = {
        if ProcessInfo.processInfo.environment["GTFSIMPORTER_NO_COLOR"] != nil {
            return true
        }
        if isatty(STDOUT_FILENO) == 0 {
            return true
        }
        return false
    }()
}

// string extension which makes ansi codes easier
extension String {
    var black: String {
        return Console.black(string: self)
    }

    var red: String {
        return Console.red(string: self)
    }

    var green: String {
        return Console.green(string: self)
    }

    var yellow: String {
        return Console.yellow(string: self)
    }

    var blue: String {
        return Console.blue(string: self)
    }

    var magenta: String {
        return Console.magenta(string: self)
    }

    var cyan: String {
        return Console.cyan(string: self)
    }

    var white: String {
        return Console.white(string: self)
    }
}
