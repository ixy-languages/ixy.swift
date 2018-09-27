import Foundation

class Mempool {
	/// use a class to wrap entry data
	class Entry {
		let pointer: UnsafeMutableRawPointer
		let size: UInt
		fileprivate(set) var inUse: Bool = false

		init(pointer: UnsafeMutableRawPointer, size: UInt) {
			self.pointer = pointer
			self.size = size
		}
	}

	internal let memory: UnsafeMutableRawPointer
	internal let entries: [Entry]
	internal var availableEntries: [Entry]

	init(memory: UnsafeMutableRawPointer, entryCount: UInt, entrySize: UInt) {
		self.memory = memory
		// create entry wrappers
		self.entries = (0..<entryCount).map {
			Entry(pointer: memory.advanced(by: Int($0 * entrySize)), size: entrySize)
		}
		// each entry is available initially
		self.availableEntries = entries
	}

	func allocEntry() -> Entry? {
		guard let last = availableEntries.popLast() else { return nil; }
		last.inUse = true
		return last
	}

	func freeEntry(entry: Entry) {
		entry.inUse = false
		self.availableEntries.append(entry)
	}
}


