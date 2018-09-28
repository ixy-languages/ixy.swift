//
//  MemoryMap.swift
//  app
//
//  Created by Thomas Günzel on 29.09.2018.
//

import Foundation

internal class MemoryMap {
	let address: UnsafeMutableRawPointer
	let size: Int
	private var locked: Bool = false

	struct Accessibility: OptionSet {
		let rawValue: Int32
	}

	struct Flags: OptionSet {
		let rawValue: Int32
	}

	enum Error: Swift.Error {
		case mmapError(Int32)
		case invalidFile
		case filesizeError
		case lockError(Int32)
		case alreadyLocked
	}

	init(fd: Int32, size: Int, access: Accessibility, flags: Flags) throws {
		guard let pointer = mmap(nil, size, access.rawValue, flags.rawValue, fd, 0),
			pointer != MAP_FAILED else {
				throw Error.mmapError(errno)
		}
		self.address = pointer
		self.size = size
	}

	deinit {
		if locked {
			munlock(self.address, self.size)
		}
		munmap(self.address, self.size)
	}

	convenience init(file: File, size: Int?, access: Accessibility, flags: Flags) throws {
		guard let path = file.path else { throw Error.invalidFile }
		let safeSize: Int = try {
			// use given size
			if let size = size { return size }
			// otherwise fetch size
			guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
				let size = attributes[FileAttributeKey.size] as? Int else {
					throw Error.filesizeError
			}
			return size
		}()

		try self.init(fd: file.fd, size: safeSize, access: access, flags: flags)
	}

	func lock() throws {
		guard locked == false else { throw Error.alreadyLocked }
		if mlock(self.address, self.size) < 0 {
			throw Error.lockError(errno)
		}
		self.locked = true
	}
}

extension MemoryMap.Accessibility {
	typealias Accessibility = MemoryMap.Accessibility

	static let none = Accessibility(rawValue: PROT_NONE)
	static let read = Accessibility(rawValue: PROT_READ)
	static let write = Accessibility(rawValue: PROT_WRITE)
	static let exec = Accessibility(rawValue: PROT_EXEC)

	static let readwrite: Accessibility = [.read, .write]
}

extension MemoryMap.Flags {
	typealias Flags = MemoryMap.Flags

	static let file = Flags(rawValue: MAP_FILE)
	static let shared = Flags(rawValue: MAP_SHARED)
	#if os(OSX)
	static let hugetable = Flags(rawValue: 0x00)
	#else
	static let hugetable = Flags(rawValue: MAP_HUGETLB)
	#endif
}
