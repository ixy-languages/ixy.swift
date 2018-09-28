//
//  Hugepage.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

struct Hugepage {
	let memoryMap: MemoryMap
	var address: UnsafeMutableRawPointer {
		return memoryMap.address
	}

	lazy private(set) var dmaAddress: DMAMemory? = {
		return DMAMemory(virtual: self.address)
	}()
	
	static let pageId: Atomic<Int> = Atomic(value: 0)

	enum Error: Swift.Error {
		case contiguousMultipageNotSupported

	}

	init(size: Int, requireContiguous: Bool = false) throws {
		let adjustedSize = try Hugepage.adjustedSize(size, requireContiguous: requireContiguous)
		let file = try Hugepage.openHugepageFile(size: adjustedSize)
		// always delete file
		defer {
			if let path = file.path,
				let err = throwsError({ try FileManager.default.removeItem(atPath: path) }) {
				print("error deleting hugepage file: \(err)")
			}
		}

		self.memoryMap = try Hugepage.createMemoryMap(file: file, size: adjustedSize)
	}

	private static func adjustedSize(_ size: Int, requireContiguous: Bool) throws -> Int {
		let adjustedSize = size.roundUpTo(multipleOf: Constants.hugepagePageSize)
		if requireContiguous && adjustedSize > Constants.hugepagePageSize {
			throw Error.contiguousMultipageNotSupported
		}
		return adjustedSize
	}

	private static func openHugepageFile(size: Int) throws -> File {
		// synthesize path
		let pageId = Hugepage.pageId.increment()
		let pid = getpid()
		let path = Constants.hugepagePath + "ixy-swift-\(pid)-\(pageId)"

		// open file and adjust page
		let file = try File(path: path, flags: O_CREAT | O_RDWR, createMode: S_IRWXU)
		try file.truncate(to: off_t(size))
		return file
	}

	private static func createMemoryMap(file: File, size: Int) throws -> MemoryMap {
		let memoryMap = try MemoryMap(file: file, size: size, access: .readwrite, flags: [.shared, .hugetable])
		try memoryMap.lock()
		return memoryMap
	}

//	static func allocate(size: Int, requireContiguous: Bool = false) -> DMAMemory? {
//		guard let virtual: UnsafeMutableRawPointer = allocate(size: size, requireContiguous: requireContiguous) else {
//			return nil;
//		}
//		return DMAMemory(virtual: virtual)
//	}

}
