import Foundation

internal class File {
	internal var fd: Int32
	internal var closeOnDealloc: Bool

	internal enum FileError: Error {
		case unknownError
		case ioError
		case readError(Int32)
		case writeError(Int32)
	}

	internal init(fd: Int32, closeOnDealloc: Bool) {
		self.fd = fd
		self.closeOnDealloc = closeOnDealloc
	}

	internal init?(path: String, flags: Int32) {
		guard let chars = path.cString(using: .utf8) else { return nil; }
		let pathPointer: UnsafePointer<CChar> = UnsafePointer(chars)
		self.fd = open(pathPointer, flags)
		self.closeOnDealloc = true
	}

	internal init?(path: String, flags: Int32, createMode: mode_t) {
		guard let chars = path.cString(using: .utf8) else { return nil; }
		let pathPointer: UnsafePointer<CChar> = UnsafePointer(chars)
		self.fd = open(pathPointer, flags, createMode)
		self.closeOnDealloc = true
	}

	deinit {
		if closeOnDealloc {
			close(fd)
		}
	}
}

// Read Support
extension File {
	// basic function to read any type from file descriptor
	internal func read<T>(_ val: inout T, offset: off_t = 0) throws {
		guard pread(fd, &val, MemoryLayout<T>.size, offset) == MemoryLayout<T>.size else {
			throw FileError.readError(errno)
		}
	}

	// concrete helpers following

	internal func read(offset: off_t = 0) throws -> Int8 {
		var val: Int8 = 0
		try self.read(&val, offset: offset)
		return val
	}

	internal func read(offset: off_t = 0) throws -> Int16 {
		var val: Int16 = 0
		try self.read(&val, offset: offset)
		return val
	}

	internal func read(offset: off_t = 0) throws -> Int32 {
		var val: Int32 = 0
		try self.read(&val, offset: offset)
		return val
	}

	internal func read(offset: off_t = 0) throws -> Int {
		var val: Int = 0
		try self.read(&val, offset: offset)
		return val
	}

	internal func read(offset: off_t = 0) throws -> UInt8 {
		var val: UInt8 = 0
		try self.read(&val, offset: offset)
		return val
	}

	internal func read(offset: off_t = 0) throws -> UInt16 {
		var val: UInt16 = 0
		try self.read(&val, offset: offset)
		return val
	}

	internal func read(offset: off_t = 0) throws -> UInt32 {
		var val: UInt32 = 0
		try self.read(&val, offset: offset)
		return val
	}

	internal func read(offset: off_t = 0) throws -> UInt {
		var val: UInt = 0
		try self.read(&val, offset: offset)
		return val
	}
}

// Write Support
extension File {
	internal func truncate(to length: off_t = 0) throws {
		if ftruncate(fd, length) == -1 {
			throw FileError.writeError(errno)
		}
	}
}
