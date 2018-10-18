//
//  Extensions.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

// MARK: - extension to round up to specific sizes
extension BinaryInteger {
	func roundUpTo(multipleOf multiple: Self) -> Self {
		let remainder = self % multiple
		return remainder == 0 ? self : (self + multiple - remainder)
	}
}

// MARK: - extension to access individual bits
extension BinaryInteger {
	subscript<B: BinaryInteger>(bit: B) -> Bool {
		return ((self >> bit) & 1) > 0
	}
}

infix operator ++<: AssignmentPrecedence
extension Int {
	/// custom operator to increment a value, resetting it to 0 when it's >= max
	///
	/// - Parameters:
	///   - value: the value to adjust
	///   - max: the max value, with value < max
	static func ++<(value: inout Int, max: Int) {
		value = value + 1
		if value >= max { value = 0 }
	}
}

func throwsError(_ block: () throws -> Void) -> Error? {
	do {
		try block()
	} catch  {
		return error
	}
	return nil
}

public extension BinaryInteger {
	public var pointerString: String {
		return "0x" + String(self, radix: 16, uppercase: false)
	}

	public var hexString: String {
		return String(self, radix: 16, uppercase: false)
	}
}
