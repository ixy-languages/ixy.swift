//
//  UnsafeRawPointer+Extensions.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

// MARK: - Extension for accessing a mutable raw pointer like an array (don't know why apple doesn't provide this)
extension UnsafeMutableRawPointer {
	subscript<T>(address: Int) -> T {
		get {
			return self.load(fromByteOffset: address, as: T.self)
		}
		set {
			self.storeBytes(of: newValue, toByteOffset: address, as: T.self)
		}
	}
}
