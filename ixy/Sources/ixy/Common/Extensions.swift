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

// MARK: - custom operator to incement the Int until a given max
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

/// simple do/try/catch wrapper that returns the error, if an error occured
///
/// - Parameter block: the block which can fail
/// - Returns: the error, if any
func throwsError(_ block: () throws -> Void) -> Error? {
	do {
		try block()
	} catch  {
		return error
	}
	return nil
}

// MARK: - extensions for pretty-printing integers
extension BinaryInteger {
	/// print the integer like a pointer (0xff00aa)
	var pointerString: String {
		return "0x" + String(self, radix: 16, uppercase: false)
	}

	/// print the integer like a hexadecimal (ff00aa)
	var hexString: String {
		return String(self, radix: 16, uppercase: false)
	}
}
