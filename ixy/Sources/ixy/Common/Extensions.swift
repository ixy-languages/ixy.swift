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
