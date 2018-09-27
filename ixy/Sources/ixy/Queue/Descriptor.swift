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
	internal var mempoolEntry: DMAMempool.Entry?
	internal let mempool: DMAMempool

	init(queuePointer: UnsafeMutablePointer<Int64>, mempool: DMAMempool) {
		self.queuePointer = queuePointer
		self.mempool = mempool
	}

	func prepareForReceiving() {
		guard let entry = self.mempool.allocEntry() else {
			print("couldn't alloc space for packet")
			return
		}
		self.mempoolEntry = entry
		queuePointer[0] = Int64(Int(bitPattern: entry.pointer.physical))
		queuePointer[1] = 0
	}

	func receivePacket() -> DMAMempool.Entry? {
		guard let entry = self.mempoolEntry else { return nil; }

		let status = ReceiveWriteback.Status.from(queuePointer)
		guard status.contains(.descriptorDone) else {
			print("packet not ready")
			return nil
		}
		guard status.contains(.endOfPacket) else {
			print("multipacket not supported")
			return nil
		}

		return entry
	}

}

extension Descriptor: DebugDump {
	func dump(_ inset: Int = 0) {
		let pre = createDumpPrefix(inset)
		print("\(pre)Descriptor \(queuePointer)")
	}
}
