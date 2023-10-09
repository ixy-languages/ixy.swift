//
//  DMAMempool.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

/// the mempool holds references to multiple entries, which can be 'allocated' for temporary usage and 'freed' when done
public struct DMAMempool {
	/// use a class to wrap entry data
	struct Entry {
		let pointer: DMAMemory
		let size: UInt
		fileprivate(set) var inUse: Bool = false

		init(pointer: DMAMemory, size: UInt) {
			self.pointer = pointer
			self.size = size
		}
	}

	/// the mempool pointer automatically "free"s an entry when it's released
	public struct Pointer {
		var entry: DMAMempool.Entry
		var mempool: DMAMempool
		let id: Int
		var size: UInt16 = 0

		static private var idCounter: Atomic<Int> = Atomic(value: 0)

		fileprivate init(entry: DMAMempool.Entry, mempool: DMAMempool) {
			self.id = Pointer.idCounter.increment()
			self.entry = entry
			self.mempool = mempool
		}

		public mutating func free() {
			var tmpPointer = self
			self.mempool.freePointer(&tmpPointer)
		}

		public func touch() {
			let virtual = self.entry.pointer.virtual
			var newValue: UInt32 = virtual.load(fromByteOffset: 0, as: UInt32.self)
			newValue += 1
			virtual.storeBytes(of: newValue, toByteOffset: 0, as: UInt32.self)
		}

		public var packetData: UnsafeBufferPointer<UInt8>? {
			get {
				return UnsafeBufferPointer<UInt8>(start: self.entry.pointer.virtual.assumingMemoryBound(to: UInt8.self), count: Int(self.size))
			}
		}
	}

	enum Error: Swift.Error {
		case invalidEntryCount
	}

	internal let memory: DMAMemory
	internal var entries: [Pointer] = []
	internal var availableEntries: [Pointer] = []

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
			let entry = Entry(pointer: dma, size: entrySize)
			return Pointer(entry: entry, mempool: self)
		}
		self.availableEntries = self.entries
	}

	mutating func getFreePointer() -> Pointer? {
		guard self.availableEntries.count > 0 else { return nil }
		var pointer = self.availableEntries.removeLast()
		pointer.entry.inUse = true
		return pointer
	}

	fileprivate mutating func freePointer(_ pointer: inout Pointer) {
		pointer.entry.inUse = false
		self.availableEntries.append(pointer)
	}
}

extension DMAMemory {
	static func byConverting(virtual: UnsafeMutableRawPointer, using pagemap: borrowing Pagemap) -> DMAMemory? {
		guard let physical = pagemap.physical(from: virtual) else { return nil; }
		return DMAMemory(virtual: virtual, physical: physical)
	}
}
