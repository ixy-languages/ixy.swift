//
//  Atomic.swift
//  app
//
//  Created by Thomas Günzel on 25.09.2018.
//

import Foundation

/// Generic wrapper for accessing an object atomically
public struct Atomic<T> {
	private let lock = DispatchSemaphore(value: 1)
	private var _value: T

	public init(value initialValue: T) {
		_value = initialValue
	}

	public var value: T {
		get {
			lock.wait()
			defer { lock.signal() }
			return _value
		}
		set {
			lock.wait()
			defer { lock.signal() }
			_value = newValue
		}
	}

	/// mutate the value suing a block
	///
	/// - Parameter transform: the block which can mutate the value
	public mutating func mutate(_ transform: (inout T) -> Void) {
		lock.wait()
		defer { lock.signal() }
		transform(&_value)
	}
}

// MARK: - Extension for Strideable types, which offer the possibility to be incremented
extension Atomic where T: Strideable {
	public mutating func increment(by: T.Stride = 1) -> T {
		lock.wait()
		defer { lock.signal() }
		_value = _value.advanced(by: by)
		return _value
	}
}

