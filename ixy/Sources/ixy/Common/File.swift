import Foundation

internal class File {
	internal var fd: Int32
	internal var closeOnDealloc: Bool
	internal var path: String?

	internal enum FileError: Error {
		case unknownError
		case internalError
		case ioError
		case readError(Int32)
		case writeError(Int32)
	}

	internal init(fd: Int32, closeOnDealloc: Bool) {
		self.fd = fd
		self.closeOnDealloc = closeOnDealloc
	}

	internal init(path: String, flags: Int32, createMode: mode_t? = nil) throws {
		guard let chars = path.cString(using: .utf8) else { throw FileError.internalError }
		let pathPointer: UnsafePointer<CChar> = UnsafePointer(chars)
		if let mode = createMode {
			self.fd = open(pathPointer, flags, mode)
		} else {
			self.fd = open(pathPointer, flags)
		}
		self.closeOnDealloc = true
		self.path = path
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

	internal func writeString(_ string: String) {
		guard let chars = string.cString(using: .utf8) else {
			print("couldnt convert string")
			return;
		}
		let pathPointer: UnsafePointer<CChar> = UnsafePointer(chars)
		write(fd, pathPointer, chars.count)
	}

	subscript<T: BinaryInteger>(offset: off_t) -> T {
		get {
			var val: T = 0
			pread(fd, &val, MemoryLayout<T>.size, offset)
			return val
		}
		set {
			var val = newValue
			pwrite(fd, &val, MemoryLayout<T>.size, offset)
		}
	}

	subscript<T>(offset: off_t) -> T? {
		get {
			var val: T?
			pread(fd, &val, MemoryLayout<T>.size, offset)
			return val
		}
		set {
			guard var val = newValue else { return }
			pwrite(fd, &val, MemoryLayout<T>.size, offset)
		}
	}
}
