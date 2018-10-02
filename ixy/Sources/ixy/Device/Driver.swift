//
//  Driver.swift
//  app
//
//  Created by Thomas Günzel on 28.09.2018.
//

import Foundation

/// abstraction for the Intel 82599 pci interface
class Driver {
	internal let address: String
	private let resource: UnsafeMutableRawPointer
	private let size: Int
	private let file: File

	enum Error: Swift.Error {
		case unknownError
		case unbindError
		case ioError
	}

	init(address: String) throws {
		self.address = address
		try Driver.removeDriver(address: address)
		try Driver.enableDMA(address: address)

		let (pointer, size, file) = try Driver.mmapResource(address: address)
//		let pointer = UnsafeMutableRawPointer.allocate(byteCount: 2097152, alignment: 1)
//		let size: Int = 2097152
		self.resource = pointer
		self.size = size
		self.file = file
	}

	deinit {
		munmap(self.resource, self.size)
	}

	func readStats() -> DeviceStats {
		return DeviceStats(resourceAddress: resource)
	}
}

fileprivate extension DeviceStats {
	init(resourceAddress addr: UnsafeMutableRawPointer) {
		self.init(transmittedPackets: addr[Int(IXGBE_GPTC)], transmittedBytes: addr[Int(IXGBE_GOTCL)],
				  receivedPackets:  addr[Int(IXGBE_GPRC)], receivedBytes: addr[Int(IXGBE_GORCL)])
	}
}

extension Driver {
//	subscript(address: Int) -> UInt32 {
//		get {
//			return resource.load(fromByteOffset: address, as: UInt32.self)
//		}
//		set {
//			resource.storeBytes(of: newValue, toByteOffset: address, as: UInt32.self)
//		}
//	}

	subscript(address: UInt32) -> UInt32 {
		get {
			return resource.load(fromByteOffset: Int(address), as: UInt32.self)
		}
		set {
			resource.storeBytes(of: newValue, toByteOffset: Int(address), as: UInt32.self)
			print("[driver] setting \(address) to \(newValue)")
		}
	}

	func wait(until address: UInt32, didClearMask mask: UInt32) {
		while self[address] & mask != 0 {
			print("[driver] waiting for flags 0x\(String(mask, radix: 16, uppercase: false)) in register 0x\(String(mask, radix: 16, uppercase: false)) to set")
			usleep(10000)
		}
	}

	func wait(until address: UInt32, didSetMask mask: UInt32) {
		while self[address] & mask == 0 {
			print("[driver] waiting for flags 0x\(String(mask, radix: 16, uppercase: false)) in register 0x\(String(mask, radix: 16, uppercase: false)) to set")
			usleep(10000)
		}
	}
}

extension LinkSpeed {
	init?(_ value: UInt32) {
		// check if up
		guard (value & IXGBE_LINKS_UP) != 0 else { return nil }
		print("links up \(value | IXGBE_LINKS_SPEED_82599)")
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

