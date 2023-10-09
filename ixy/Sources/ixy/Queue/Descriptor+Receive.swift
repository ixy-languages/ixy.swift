//
//  Descriptor+Receive.swift
//  ixy
//
//  Created by Thomas Günzel on 28.10.2018.
//

import Foundation

// MARK: - Receiving
extension Descriptor {
	mutating func prepareForReceiving() {
		// allocate new mempool entry if necessary
		guard self.packetPointer == nil, let packetPointer = self.packetMempool.getFreePointer() else {
			Log.warn("Couldn't alloc space for packet", component: .rx)
			exit(1)
			//return
		}
		self.packetPointer = packetPointer
		queuePointer[0] = UInt64(Int(bitPattern: packetPointer.entry.pointer.physical))
		queuePointer[1] = 0
	}

	enum ReceiveResponse {
		case unknownError
		case notReady
		case multipacket
		case packet(DMAMempool.Pointer)
	}

	mutating func receivePacket() -> ReceiveResponse {
		guard var entry = self.packetPointer else {
			Log.error("No packet pointer", component: .rx)
			return .unknownError;
		}

		// -- USING SWIFT PACKET ACCESS --
		let status = ReceiveWriteback.Status.from(queuePointer)
		guard status.contains(.descriptorDone) else {
			return .notReady
		}

		// remove packet buffer from descriptor, the client needs to handle it
		self.packetPointer = nil

		guard status.contains(.endOfPacket) else {
			Log.error("Multipacket unsupported", component: .rx)
			return .multipacket
		}

		entry.size = ReceiveWriteback.lengthFrom(queuePointer)

		return .packet(entry)
	}
}
