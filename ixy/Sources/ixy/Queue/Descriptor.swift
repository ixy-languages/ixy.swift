//
//  DescriptorRing.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

struct ReceiveWriteback {
	struct Status: OptionSet {
		let rawValue: Int8

		static let descriptorDone = Status(rawValue: (1 << 0))
		static let endOfPacket = Status(rawValue: (1 << 1))

		static func from(_ pointer: UnsafeMutablePointer<Int64>) -> Status {
			return Status(rawValue: Int8(pointer[1] & 0x03))
		}
	}

	static func lengthFrom(_ pointer: UnsafeMutablePointer<Int64>) -> Int16 {
		return Int16((pointer[1] >> 32) & 0xFFFF)
	}
}



class Descriptor {
	internal let queuePointer: UnsafeMutablePointer<Int64>
	internal var packetPointer: DMAMempool.Pointer?
	internal let packetMempool: DMAMempool

	init(queuePointer: UnsafeMutablePointer<Int64>, mempool: DMAMempool) {
		self.queuePointer = queuePointer
		self.packetMempool = mempool
	}
}

// MARK: - Receiving
extension Descriptor {
	func prepareForReceiving() {
		// allocate new mempool entry if necessary
		guard self.packetPointer == nil, let packetPointer = self.packetMempool.getFreePointer() else {
			print("couldn't alloc space for packet")
			return
		}
		self.packetPointer = packetPointer
		queuePointer[0] = Int64(Int(bitPattern: packetPointer.entry.pointer.physical))
		queuePointer[1] = 0
	}

	enum ReceiveResponse {
		case unknownError
		case notReady
		case multipacket
		case packet(DMAMempool.Pointer)
	}

	func receivePacket() -> ReceiveResponse {
		guard let entry = self.packetPointer else { return .unknownError; }

		let status = ReceiveWriteback.Status.from(queuePointer)
		guard status.contains(.descriptorDone) else {
			return .notReady
		}
		guard status.contains(.endOfPacket) == false else {
			return .multipacket
		}

		// remove packet buffer from descriptor, the client needs to handle it
		self.packetPointer = nil
		return .packet(entry)
	}
}

extension Descriptor: DebugDump {
	func dump(_ inset: Int = 0) {
		let pre = createDumpPrefix(inset)
		print("\(pre)Descriptor \(queuePointer)")
	}
}
