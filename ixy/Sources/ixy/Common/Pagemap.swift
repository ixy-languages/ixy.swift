//
//  PagemapFile.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

class Pagemap: File {
	static var pagesize: UInt = {
		return UInt(sysconf(Int32(_SC_PAGESIZE)))
	}()

	init() throws {
		try super.init(path: Constants.pagemapPath, flags: O_RDONLY)
	}

	func physical(from virtual: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
		let virtualIntAddress = UInt(bitPattern: virtual)
		// TODO: check if correct calculation due to possible precedence differences!
		let offset: off_t = off_t(virtualIntAddress / Pagemap.pagesize * UInt(MemoryLayout<Int>.size))
		do {
			let pageNumber: UInt = try self.read(offset: offset)
			// TODO: check if correct calculation due to possible precedence differences!
			let physicalIntAddress = ((pageNumber & 0x7f_ffff_ffff_ffff) * Pagemap.pagesize) + (virtualIntAddress % Pagemap.pagesize)
			let physical = UnsafeMutableRawPointer(bitPattern: physicalIntAddress)
			return physical
		} catch {
			print("error: \(error)")
			return nil
		}
	}
}
