//
//  DMAMemory.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

struct DMAMemory {
	let virtual: UnsafeMutableRawPointer
	let physical: UnsafeMutableRawPointer

	init(virtual: UnsafeMutableRawPointer, physical: UnsafeMutableRawPointer) {
		self.virtual = virtual
		self.physical = physical
	}

	init?(virtual: UnsafeMutableRawPointer) {
		self.virtual = virtual
		// Generate Physical
		guard let physical = DMAMemory.convertVirtualToPhysical(virtual: virtual) else { return nil; }
		self.physical = physical
	}

	static private func convertVirtualToPhysical(virtual: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
		#if os(OSX)
		let mockPhysical = UnsafeMutableRawPointer(bitPattern: Int(bitPattern: virtual) | 0x0F00_0000_0000_0000)
		return mockPhysical
		#elseif os(Linux)
		guard let pagemap = Pagemap() else { return nil; }
		return pagemap.physical(from: virtual)
		#endif
	}
}
