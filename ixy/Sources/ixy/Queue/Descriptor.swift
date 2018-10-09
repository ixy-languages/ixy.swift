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
		queuePointer[0] = UInt64(Int(bitPattern: packetPointer.entry.pointer.physical))
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
		entry.size = ReceiveWriteback.lengthFrom(queuePointer)

//		Log.debug("[\(entry.id)] packet size: \(entry.size)", component: .rx)

		return .packet(entry)
	}
}

func pointerToInt(_ pointer: UnsafeMutableRawPointer) -> UInt64 {
	return UInt64(Int(bitPattern: pointer))
}

extension Descriptor {
	var transmitted: Bool {
		return self.packetPointer != nil && TransmitWriteback.done(queuePointer)
	}

	func cleanUpTransmitted() {
		self.queuePointer[0] = 0
		self.queuePointer[1] = 0
		self.packetPointer = nil
	}

//	func scheduleForTransmission(packetPointer: DMAMempool.Pointer) {
//		self.packetPointer = packetPointer
//		queuePointer[0] = pointerToInt(packetPointer.entry.pointer.physical)//UInt64(Int(bitPattern: packetPointer.entry.pointer.physical))
//		let size: UInt32 = UInt32(packetPointer.size)
//		//let lower: UInt32 = (IXGBE_ADVTXD_DCMD_EOP | IXGBE_ADVTXD_DCMD_RS | IXGBE_ADVTXD_DCMD_IFCS | IXGBE_ADVTXD_DCMD_DEXT | IXGBE_ADVTXD_DTYP_DATA | size)
//		let lower: UInt32 = (0x2B300000 as UInt32 | size)
////		let upper: UInt32 = size << IXGBE_ADVTXD_PAYLEN_SHIFT
//		let upper: UInt32 = size << 14
//		queuePointer[1] = UInt64((UInt64(upper) << 32) | UInt64(lower))
////		Log.debug("scheduled \(packetPointer.entry.pointer.physical)", component: .tx)
////		Log.debug("Header: \(queuePointer[0].hexString) \(queuePointer[1].hexString)", component: .tx)
//	}

	func scheduleForTransmission(packetPointer: DMAMempool.Pointer) {
		self.packetPointer = packetPointer
		c_ixy_tx_setup(queuePointer, packetPointer.size, packetPointer.entry.pointer.physical)
	}
}

extension Descriptor: DebugDump {
	func dump(_ inset: Int = 0) {
		let pre = createDumpPrefix(inset)
		print("\(pre)Descriptor \(queuePointer)")
	}
}
