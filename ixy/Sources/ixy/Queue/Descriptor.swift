//
//  DescriptorRing.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation
import c_ixy

struct ReceiveWriteback {
	struct Status: OptionSet {
		let rawValue: Int8

		static let descriptorDone = Status(rawValue: (1 << 0))
		static let endOfPacket = Status(rawValue: (1 << 1))

		static func from(_ pointer: UnsafeMutablePointer<UInt64>) -> Status {
//			Log.debug("Header: \(pointer[0].hexString) \(pointer[1].hexString)", component: .rx)
			return Status(rawValue: Int8(pointer[1] & 0x03))
		}
	}

	static func lengthFrom(_ pointer: UnsafeMutablePointer<UInt64>) -> UInt16 {
		return UInt16((pointer[1] >> 32) & 0xFFFF)
	}
}

struct TransmitWriteback {
	static func done(_ pointer: UnsafeMutablePointer<UInt64>) -> Bool {
//		Log.debug("Header: \(pointer[0].hexString) \(pointer[1].hexString)", component: .tx)
		let status64: UInt64 = pointer[1]
		return status64[32]
	}
}


class Descriptor {
	internal let queuePointer: UnsafeMutablePointer<UInt64>
	internal var packetPointer: DMAMempool.Pointer?
	internal let packetMempool: DMAMempool

	init(queuePointer: UnsafeMutablePointer<UInt64>, mempool: DMAMempool) {
		self.queuePointer = queuePointer
		self.packetMempool = mempool
	}
}

// MARK: - Receiving
extension Descriptor {
	func prepareForReceiving() {
		// allocate new mempool entry if necessary
		guard self.packetPointer == nil, let packetPointer = self.packetMempool.getFreePointer() else {
			Log.warn("couldn't alloc space for packet", component: .rx)
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
			Log.error("no packet pointer", component: .rx)
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
			Log.error("multipacket unsupported", component: .rx)
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

func pointerToInt(_ pointer: UnsafeMutableRawPointer) -> UInt64 {
	return UInt64(Int(bitPattern: pointer))
}

extension Descriptor {
	#if USE_C_PACKET_ACCESS
	var transmitted: Bool {
		return self.packetPointer != nil && c_ixy_tx_desc_done(queuePointer)
	}
	#else
	var transmitted: Bool {
		return self.packetPointer != nil && TransmitWriteback.done(queuePointer)
	}
	#endif

	internal func cleanUp() {
		self.queuePointer[0] = 0
		self.queuePointer[1] = 0
		self.packetPointer = nil
	}

	func cleanUpTransmitted() {
		self.queuePointer[0] = 0
		self.queuePointer[1] = 0
		guard let packetPointer = self.packetPointer else { Log.warn("no packet pointer", component: .tx); return }
		packetPointer.free()
		self.packetPointer = nil
	}

	func scheduleForTransmission(packetPointer: DMAMempool.Pointer) {
		self.packetPointer = packetPointer
		assert(queuePointer[0] == 0, "queue pointer not clean!")
		c_ixy_tx_setup(queuePointer, packetPointer.size, packetPointer.entry.pointer.physical)
	}
}

