//
//  DMAMemory.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

/// holds a reference to the virtual and physical address, so the pagemap lookup is only necessary once for each address
struct DMAMemory {
	let virtual: UnsafeMutableRawPointer
	let physical: UnsafeMutableRawPointer

	enum Error: Swift.Error {
		case fetchingPhysicalAddress
	}

	init(virtual: UnsafeMutableRawPointer, physical: UnsafeMutableRawPointer) {
		self.virtual = virtual
		self.physical = physical
	}


	init(virtual: UnsafeMutableRawPointer) throws {
		self.virtual = virtual
		// Generate Physical
		guard let physical = DMAMemory.convertVirtualToPhysical(virtual: virtual) else { throw Error.fetchingPhysicalAddress }
		self.physical = physical
	}

	static private func convertVirtualToPhysical(virtual: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
		#if os(OSX)
		// no pagemap on macosx. only for debugging/compiling the code
		let mockPhysical = UnsafeMutableRawPointer(bitPattern: Int(bitPattern: virtual) | 0x0F00_0000_0000_0000)
		return mockPhysical
		#elseif os(Linux)
		guard let pagemap = try? Pagemap() else { return nil; }
		return pagemap.physical(from: virtual)
		#endif
	}
}

extension DMAMemory {
	init(virtual: UnsafeMutableRawPointer, using pagemap: Pagemap) throws {
		self.virtual = virtual
		// Generate Physical
		guard let physical = pagemap.physical(from: virtual) else { throw Error.fetchingPhysicalAddress }
		self.physical = physical
	}
}
