//
//  Hugepage.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

struct Hugepage {
	
	static let pageId: Atomic<Int> = Atomic(value: 0)

	static func allocate(size: Int, requireContiguous: Bool = false) -> UnsafeMutableRawPointer? {
		// adjust size to fill whole pages
		let adjustedSize = size.roundUpTo(multipleOf: Constants.hugepagePageSize)
		if requireContiguous && adjustedSize > Constants.hugepagePageSize {
			print("contigous memory not supported yet");
			return nil;
		}

		// synthesize path
		let pageId = Hugepage.pageId.increment()
		let pid = getpid()
		let path = Constants.hugepagePath + "ixy-swift-\(pid)-\(pageId)"

		// open file and adjust page
		guard let file = File(path: path, flags: O_CREAT | O_RDWR, createMode: S_IRWXU) else {
			print("error opening hugepage")
			return nil
		}
		do {
			try file.truncate(to: off_t(adjustedSize))
		} catch {
			print("error resizing page: \(error)")
			return nil
		}

		// mmap the file
		guard let pointer = mmap(nil, size, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FILE, file.fd, 0),
			pointer != MAP_FAILED else {
				print("mmap failed: \(errno)")
				return nil
		}

		return pointer
	}

	static func allocate(size: Int, requireContiguous: Bool = false) -> DMAMemory? {
		guard let virtual: UnsafeMutableRawPointer = allocate(size: size, requireContiguous: requireContiguous) else {
			return nil;
		}
		return DMAMemory(virtual: virtual)
	}

}
