import Foundation

/// a simple file wrapper class, which uses file descriptors to access the file
internal struct File {
	internal var fd: Int32
	internal var closeOnDealloc: Bool
	internal var path: String?

	internal enum FileError: Error {
		case unknownError
		case internalError
		case ioError
		case openError(Int32)
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
		guard self.fd >= 0 else { throw FileError.openError(errno) }
		self.closeOnDealloc = true
		self.path = path
	}

	/*deinit {
		if closeOnDealloc {
			close(fd)//fixme: close file descriptor
		}
	}*/
}

// Read Support
extension File {
	// basic function to read any type from file descriptor
	internal func read<T>(_ val: inout T, offset: off_t = 0) throws {
		guard pread(fd, &val, MemoryLayout<T>.size, offset) == MemoryLayout<T>.size else {
			throw FileError.readError(errno)
		}
	}

	// using the BinaryInteger type it's possible to initialize a var with value 0 in the body
	internal func read<T: BinaryInteger>(offset: off_t) throws -> T {
		var val: T = 0
		guard pread(fd, &val, MemoryLayout<T>.size, offset) == MemoryLayout<T>.size else {
			throw FileError.readError(errno)
		}
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
			Log.error("Couldn't get c-string from \(string)", component: .file)
			return;
		}
		let pathPointer: UnsafePointer<CChar> = UnsafePointer(chars)
		let bytesToWrite = chars.count - 1
		let bytesWritten = write(fd, pathPointer, bytesToWrite)
		assert(bytesWritten == bytesToWrite, "write complete string \(errno) \(bytesWritten) \(chars.count): \(chars)")
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
