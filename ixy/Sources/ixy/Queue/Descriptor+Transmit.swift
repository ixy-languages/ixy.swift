//
//  Descriptor+Transmit.swift
//  ixy
//
//  Created by Thomas Günzel on 28.10.2018.
//

import Foundation

extension Descriptor {
	var transmitted: Bool {
		return /*self.packetPointer != nil &&*/ TransmitWriteback.done(queuePointer)
	}

	internal mutating func cleanUp() {
		self.queuePointer[0] = 0
		self.queuePointer[1] = 0
		self.packetPointer = nil
	}

	mutating func cleanUpTransmitted() {
		self.queuePointer[0] = 0
		self.queuePointer[1] = 0
		guard var packetPointer = self.packetPointer else { Log.warn("No packet pointer", component: .tx); fatalError("oops") }
		packetPointer.free()
		self.packetPointer = nil
	}

	mutating func scheduleForTransmission(packetPointer: DMAMempool.Pointer) {
		self.packetPointer = packetPointer
		assert(queuePointer[0] == 0, "Queue pointer not clean!")
		let size = UInt32(packetPointer.size)
		let lower: UInt32 = (IXGBE_ADVTXD_DCMD_EOP | IXGBE_ADVTXD_DCMD_RS | IXGBE_ADVTXD_DCMD_IFCS | IXGBE_ADVTXD_DCMD_DEXT | IXGBE_ADVTXD_DTYP_DATA | size)
		let upper: UInt32 = size << IXGBE_ADVTXD_PAYLEN_SHIFT
		queuePointer[0] = UInt64(Int(bitPattern: packetPointer.entry.pointer.physical))
		queuePointer[1] = UInt64((UInt64(upper) << 32) | UInt64(lower))
	}
}


