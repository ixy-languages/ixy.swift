//
//  UnsafeRawPointer+Extensions.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

extension UnsafeMutableRawPointer {
//	subscript<T>(address: Int) -> T {
//		return self.load(fromByteOffset: address, as: T.self)
//	}

	subscript<T>(address: Int) -> T {
		get {
			return self.load(fromByteOffset: address, as: T.self)
		}
		set {
			self.storeBytes(of: newValue, toByteOffset: address, as: T.self)
		}
	}
}
