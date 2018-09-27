//
//  DMAMempool.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

class DMAMempool {
	/// use a class to wrap entry data
	class Entry {
		let pointer: DMAMemory
		let size: UInt
		fileprivate(set) var inUse: Bool = false

		init(pointer: DMAMemory, size: UInt) {
			self.pointer = pointer
			self.size = size
		}
	}

	internal let memory: DMAMemory
	internal let entries: [Entry]
	internal var availableEntries: [Entry]

	init?(memory: UnsafeMutableRawPointer, entrySize: UInt, entryCount: UInt) {
		guard entryCount > 0 else { print("buffer with 0 pakets not supported"); return nil; }
		guard let dmaMemory = DMAMemory(virtual: memory) else { return nil; }
		guard let pagemap = Pagemap() else { return nil; }

		self.memory = dmaMemory
		// create entry wrappers
		self.entries = (0..<entryCount).compactMap {
			let advanced = memory.advanced(by: Int($0 * entrySize))
			guard let dma = DMAMemory.byConverting(virtual: advanced, using: pagemap) else {
				print("couldn't map to physical address: \(advanced)");
				return nil;
			}
			return Entry(pointer: dma, size: entrySize)
		}
		// each entry is available initially
		self.availableEntries = entries
	}

	func allocEntry() -> Entry? {
		guard let last = availableEntries.popLast() else {
			print("no pakets left in buffer")
			return nil;
		}
		last.inUse = true
		return last
	}

	func freeEntry(entry: Entry) {
		entry.inUse = false
		self.availableEntries.append(entry)
	}
}

extension DMAMemory {
	static func byConverting(virtual: UnsafeMutableRawPointer, using pagemap: Pagemap) -> DMAMemory? {
		guard let physical = pagemap.physical(from: virtual) else { return nil; }
		return DMAMemory(virtual: virtual, physical: physical)
	}
}
