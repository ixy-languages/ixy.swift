//
//  Log.swift
//  ixy
//
//  Created by Thomas Günzel on 04.10.2018.
//

import Foundation

/// basic logger with debug/info/warn/error levels and some components
public struct Log {
	static public var enableColors: Bool = true
	static var componentLength: Int? = 6 {
		didSet {
			if let length = componentLength {
				nilComponentString = "[\(String(repeating: "?", count: length))] "
			} else {
				nilComponentString = ""
			}
		}
	}
	public static var level: Log.Level = .info
	private static var nilComponentString: String = "[      ] "

	public enum Level: UInt {
		case debug = 4
		case info = 3
		case warn = 2
		case error = 1
	}

	internal enum Component: String {
		case main = 	"main"
		case device = 	"device"
		case driver = 	"driver"
		case queue = 	"queue"
		case mempool = 	"memory"
		case pagemap = 	"pgmap"
		case file = 	"file"
		case tx = 		"tx    "
		case rx = 		"    rx"
	}

	public static func log(_ message: @autoclosure () -> String, level: Level = .debug, component: String) {
		guard level.rawValue <= self.level.rawValue else { return }
		guard let length = self.componentLength else {
			// component length = nil, so just print message
			print("\(message())");
			return
		}
		// format and prepend the component
		let componentString = "[\(component.padding(toLength: length, withPad: " ", startingAt: 0))]"
		print("\(level.escape(componentString, escaped: enableColors)) \(message())")
	}

	internal static func log(_ message: @autoclosure () -> String, level: Level = .debug, component: Component) {
		self.log(message, level: level, component: component.rawValue)
	}

	internal static func error(_ message: @autoclosure () -> String, component: Component) {
		log(message, level: .error, component: component)
	}

	internal static func warn(_ message: @autoclosure () -> String, component: Component) {
		log(message, level: .warn, component: component)
	}

	internal static func info(_ message: @autoclosure () -> String, component: Component) {
		log(message, level: .info, component: component)
	}

	internal static func debug(_ message: @autoclosure () -> String, component: Component) {
		log(message, level: .debug, component: component)
	}

	internal static func formatComponent(_ component: String) -> String? {
		guard let length = self.componentLength else { return nil }
		return "[\(component.padding(toLength: length, withPad: " ", startingAt: 0))]"
	}
}

extension Log.Level {
	var ansiEscapeCode: String? {
		switch self {
		case .debug:
			return nil
		case .info:
			return "\u{1B}[37m"
		case .warn:
			return "\u{1B}[33m"
		case .error:
			return "\u{1B}[31m"
		}
	}

	func escape(_ string: String, escaped: Bool) -> String {
		if escaped, let escapeCode = ansiEscapeCode {
			return "\(escapeCode)\(string)\u{1B}[0m"
		} else {
			return string
		}
	}
}
