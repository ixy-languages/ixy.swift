//
//  Descriptor+Receive.swift
//  ixy
//
//  Created by Thomas Günzel on 28.10.2018.
//

import Foundation
import c_ixy

// MARK: - Receiving
extension Descriptor {
	func prepareForReceiving() {
		// allocate new mempool entry if necessary
		guard self.packetPointer == nil, let packetPointer = self.packetMempool.getFreePointer() else {
			Log.warn("Couldn't alloc space for packet", component: .rx)
			exit(1)
			//return
		}
		self.packetPointer = packetPointer
		#if USE_C_INT_CAST
		queuePointer[0] = c_ixy_u64_from_pointer(self.packetPointer?.entry.pointer.physical)
		#else
		queuePointer[0] = UInt64(Int(bitPattern: packetPointer.entry.pointer.physical))
		#endif
		queuePointer[1] = 0
	}

	enum ReceiveResponse {
		case unknownError
		case notReady
		case multipacket
		case packet(DMAMempool.Pointer)
	}

	func receivePacket() -> ReceiveResponse {
		guard let entry = self.packetPointer else {
			Log.error("No packet pointer", component: .rx)
			return .unknownError;
		}

		#if USE_C_PACKET_ACCESS
		// -- USING C PACKET ACCESS --
		let status = c_ixy_rx_desc_ready(queuePointer)
		if status == 0 {
			return .notReady
		}
		if status == -1 {
			return .multipacket
		}
		self.packetPointer = nil
		#else
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
		#endif

		#if USE_C_INT_CAST
		entry.size = c_ixy_u16_from_u32(c_ixy_rx_desc_size(queuePointer))
		#else
		entry.size = ReceiveWriteback.lengthFrom(queuePointer)
		#endif

		return .packet(entry)
	}
}
