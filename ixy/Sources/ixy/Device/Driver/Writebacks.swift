//
//  Writebacks.swift
//  app
//
//  Created by Thomas Günzel on 28.10.2018.
//

import Foundation

struct ReceiveWriteback {
	struct Status: OptionSet {
		let rawValue: Int8

		static let descriptorDone = Status(rawValue: (1 << 0))
		static let endOfPacket = Status(rawValue: (1 << 1))

		static func from(_ pointer: UnsafeMutablePointer<UInt64>) -> Status {
			return Status(rawValue: Int8(pointer[1] & 0x03))
		}
	}

	static func lengthFrom(_ pointer: UnsafeMutablePointer<UInt64>) -> UInt16 {
		return UInt16((pointer[1] >> 32) & 0xFFFF)
	}
}

struct TransmitWriteback {
	static func done(_ pointer: UnsafeMutablePointer<UInt64>) -> Bool {
		let status64: UInt64 = pointer[1]
		return status64[32]
	}
}

