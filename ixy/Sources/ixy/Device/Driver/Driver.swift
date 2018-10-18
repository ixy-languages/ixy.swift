//
//  Driver.swift
//  app
//
//  Created by Thomas Günzel on 28.09.2018.
//

import Foundation
import c_ixy

/// abstraction for the Intel 82599 pci interface
class Driver {
	internal let address: String
	private let resource: UnsafeMutableRawPointer
//	private let size: Int
//	private let file: File
	private let mmap: MemoryMap

	enum Error: Swift.Error {
		case unknownError
		case unbindError
		case ioError
		case initializationError
	}

	init(address: String) throws {
		self.address = address
		try Driver.removeDriver(address: address)
		try Driver.enableDMA(address: address)

		let mmap = try Driver.mmapResource(address: address)
		self.mmap = mmap
		self.resource = mmap.address
//		self.size = size
//		self.file = file
	}

	func readStats() -> DeviceStats {
		return DeviceStats(resourceAddress: resource)
	}
}

fileprivate extension DeviceStats {
	init(resourceAddress addr: UnsafeMutableRawPointer) {
		let test: UInt32 = addr[Int(IXGBE_RXDGPC)]
		self.init(transmittedPackets: addr[Int(IXGBE_GPTC)], transmittedBytes: UInt64(test),
				  receivedPackets:  addr[Int(IXGBE_GPRC)], receivedBytes: UInt64(dbg_desc_err_count(addr)))
//				  receivedPackets:  addr[Int(IXGBE_GPRC)], receivedBytes: addr[Int(IXGBE_GORCL)])
//		self.init(transmittedPackets: addr[Int(IXGBE_TPT)], transmittedBytes: addr[Int(IXGBE_GOTCL)],
//				  receivedPackets:  addr[Int(IXGBE_TPR)], receivedBytes: addr[Int(IXGBE_GORCL)])RPDC

		Log.debug("Fetched Stats: \(self)", component: .driver)
	}
}

extension Driver {
	subscript(address: UInt32) -> UInt32 {
		get {
			return resource.load(fromByteOffset: Int(address), as: UInt32.self)
		}
		set {
			resource.storeBytes(of: newValue, toByteOffset: Int(address), as: UInt32.self)
			Log.debug("setting \(address) to \(newValue)", component: .driver)
		}
	}

	func wait(until address: UInt32, didClearMask mask: UInt32) {
		while self[address] & mask != 0 {
			Log.debug("waiting for flags 0x\(String(mask, radix: 16, uppercase: false)) in register 0x\(String(mask, radix: 16, uppercase: false)) to clear", component: .driver)
			usleep(10000)
		}
	}

	func wait(until address: UInt32, didSetMask mask: UInt32) {
		while self[address] & mask == 0 {
			Log.debug("waiting for flags 0x\(String(mask, radix: 16, uppercase: false)) in register 0x\(String(mask, radix: 16, uppercase: false)) to set", component: .driver)
			usleep(10000)
		}
	}
}

extension LinkSpeed {
	init?(_ value: UInt32) {
		// check if up
		guard (value & IXGBE_LINKS_UP) != 0 else { return nil }
		Log.debug("link up!", component: .driver)
		switch (value & IXGBE_LINKS_SPEED_82599) {
		case IXGBE_LINKS_SPEED_100_82599:
			self = .mbit100
		case IXGBE_LINKS_SPEED_1G_82599:
			self = .gbit1
		case IXGBE_LINKS_SPEED_10G_82599:
			self = .gbit10
		default:
			return nil
		}
	}
}

