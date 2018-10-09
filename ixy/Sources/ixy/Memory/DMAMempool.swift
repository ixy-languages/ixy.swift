//
//  DMAMempool.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

public class DMAMempool {
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

	/// the mempool pointer automatically "free"s an entry when it's released
	public class Pointer {
		let entry: DMAMempool.Entry
		let mempool: DMAMempool
		let id: Int
		var size: UInt16 = 0

		static private var idCounter: Atomic<Int> = Atomic(value: 0)

		fileprivate init(entry: DMAMempool.Entry, mempool: DMAMempool) {
			self.id = Pointer.idCounter.increment()
			self.entry = entry
			self.mempool = mempool
		}

		deinit {
			mempool.freeEntry(entry: self.entry)
		}

		public func touch() {
			let virtual = self.entry.pointer.virtual
			let newValue: UInt32 = virtual.load(fromByteOffset: 0, as: UInt32.self)
			virtual.storeBytes(of: newValue, toByteOffset: 0, as: UInt32.self)
		}
	}

	enum Error: Swift.Error {
		case invalidEntryCount
	}

	internal let memory: DMAMemory
	internal let entries: [Entry]
	internal var availableEntries: [Entry]

	init(memory: UnsafeMutableRawPointer, entrySize: UInt, entryCount: UInt) throws {
		guard entryCount > 0 else {
			throw Error.invalidEntryCount
		}
		let dmaMemory = try DMAMemory(virtual: memory)
		let pagemap = try Pagemap()

		self.memory = dmaMemory
		// create entry wrappers
		self.entries = try (0..<entryCount).compactMap {
			let advanced = memory.advanced(by: Int($0 * entrySize))
			let dma = try DMAMemory(virtual: advanced, using: pagemap)
			return Entry(pointer: dma, size: entrySize)
		}
		// each entry is available initially
		self.availableEntries = entries
	}

	func getFreePointer() -> Pointer? {
		guard let entry = self.allocEntry() else { return nil }
		return Pointer(entry: entry, mempool: self)
	}

	private func allocEntry() -> Entry? {
		guard let last = availableEntries.popLast() else {
			Log.error("no entries left in buffer", component: .mempool)
			return nil;
		}
		last.inUse = true
		//Log.debug("alloc \(last.pointer.virtual) (available=\(self.availableEntries.count))", component: .mempool)
		return last
	}

	private func freeEntry(entry: Entry) {
		entry.inUse = false
		self.availableEntries.append(entry)
//		Log.debug("free \(entry.pointer.virtual) (available=\(self.availableEntries.count))", component: .mempool)
	}
}

extension DMAMemory {
	static func byConverting(virtual: UnsafeMutableRawPointer, using pagemap: Pagemap) -> DMAMemory? {
		guard let physical = pagemap.physical(from: virtual) else { return nil; }
		return DMAMemory(virtual: virtual, physical: physical)
	}
}
