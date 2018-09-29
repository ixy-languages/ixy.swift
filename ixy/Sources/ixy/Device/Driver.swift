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

	enum Error: Swift.Error {
		case unknownError
		case unbindError
		case ioError
	}

	init(address: String) throws {
		self.address = address
		try Driver.removeDriver(address: address)
		let (pointer, size) = try Driver.mmapResource(address: address)
		self.resource = pointer
		self.size = size
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
	subscript(address: Int) -> UInt32 {
		get {
			return resource.load(fromByteOffset: address, as: UInt32.self)
		}
		set {
			resource.storeBytes(of: newValue, toByteOffset: address, as: UInt32.self)
		}
	}

	subscript(address: UInt32) -> UInt32 {
		get {
			return resource.load(fromByteOffset: Int(address), as: UInt32.self)
		}
		set {
			resource.storeBytes(of: newValue, toByteOffset: Int(address), as: UInt32.self)
		}
	}

	func wait(until address: UInt32, didClearMask mask: UInt32) {
		while self[Int(address)] & mask != 0 {
			print("[driver] waiting for flags 0x\(String(mask, radix: 16, uppercase: false)) in register 0x\(String(mask, radix: 16, uppercase: false)) to set")
			usleep(10000)
		}
	}

	func wait(until address: UInt32, didSetMask mask: UInt32) {
		while self[Int(address)] & mask == 0 {
			print("[driver] waiting for flags 0x\(String(mask, radix: 16, uppercase: false)) in register 0x\(String(mask, radix: 16, uppercase: false)) to set")
			usleep(10000)
		}
	}
}
