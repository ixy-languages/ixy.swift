//
//  DMAMempool.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

/// the mempool holds references to multiple entries, which can be 'allocated' for temporary usage and 'freed' when done
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

		public func free() {
			self.mempool.freePointer(self)
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
//	internal let availableEntries: FixedStack<Pointer>
//	internal var availableEntries: [Unmanaged<Pointer>] = []
	internal var availableEntries: [Pointer] = []

	init(memory: UnsafeMutableRawPointer, entrySize: UInt, entryCount: UInt) throws {
		guard entryCount > 0 else {
			throw Error.invalidEntryCount
		}
		let dmaMemory = try DMAMemory(virtual: memory)
		let pagemap = try Pagemap()

		self.memory = dmaMemory
//		self.availableEntries = FixedStack(size: Int(entryCount))
		// create entry wrappers
		self.entries = try (0..<entryCount).compactMap {
			let advanced = memory.advanced(by: Int($0 * entrySize))
			let dma = try DMAMemory(virtual: advanced, using: pagemap)
			let entry = Entry(pointer: dma, size: entrySize)
			return Pointer(entry: entry, mempool: self)
		}
		self.availableEntries = self.entries
//		self.availableEntries = self.entries.map { return Unmanaged<Pointer>.passUnretained($0)	}
//		self.availableEntries.initialize(from: self.entries)
	}

//	func getFreePointer() -> Pointer? {
//		return self.availableEntries.pop()
//	}
//
//	fileprivate func freePointer(_ pointer: Pointer) {
//		self.availableEntries.push(pointer)
//	}


//	func getFreePointer() -> Pointer? {
//		guard self.availableEntries.count > 0 else { return nil }
//		let pointer = self.availableEntries.removeLast().takeUnretainedValue()
//		pointer.entry.inUse = true
//		return pointer
//	}
//
//	fileprivate func freePointer(_ pointer: Pointer) {
//		pointer.entry.inUse = false
//		self.availableEntries.append(Unmanaged.passUnretained(pointer))
//		//Log.info("did free \(pointer.entry.pointer.virtual)", component: .mempool)
//		//		Log.debug("free \(entry.pointer.virtual) (available=\(self.availableEntries.count))", component: .mempool)
//	}


	func getFreePointer() -> Pointer? {
		guard self.availableEntries.count > 0 else { return nil }
		let pointer = self.availableEntries.removeLast()
		pointer.entry.inUse = true
		return pointer
	}

	fileprivate func freePointer(_ pointer: Pointer) {
		pointer.entry.inUse = false
		self.availableEntries.append(pointer)
		//Log.info("did free \(pointer.entry.pointer.virtual)", component: .mempool)
//		Log.debug("free \(entry.pointer.virtual) (available=\(self.availableEntries.count))", component: .mempool)
	}
}

extension DMAMemory {
	static func byConverting(virtual: UnsafeMutableRawPointer, using pagemap: Pagemap) -> DMAMemory? {
		guard let physical = pagemap.physical(from: virtual) else { return nil; }
		return DMAMemory(virtual: virtual, physical: physical)
	}
}
