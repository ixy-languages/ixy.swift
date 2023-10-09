//
//  Config.swift
//  app
//
//  Created by Thomas Günzel on 25.09.2018.
//

import Foundation

/// simple wrapper class based on file for a pci device
internal struct DeviceConfig: ~Copyable {
	let file: File
	internal init(address: PCIAddress) throws {
		let path = address.path + "/config"
		try file = File(path: path, flags: O_RDONLY)
	}

	var vendorID: UInt16 {
		return (try? file.read(offset: 0x00)) ?? 0
	}

	var deviceID: UInt16 {
		return (try? file.read(offset: 0x02)) ?? 0
	}

	var classCode: UInt32 {
		var code: UInt32
		do {
			// Datasheet P755
			// Register at 0x08 = [RevID:8][ClassCode:24]
			// -> read from 0x08 but discard first 8 bits
			try code = file.read(offset: 0x08)
			code = ((code >> 8) & 0xFF_FFFF)
		} catch {
			code = 0
		}
		return code
	}

	var description: String {
		let vendor = String(self.vendorID, radix: 16, uppercase: true)
		let device = String(self.deviceID, radix: 16, uppercase: true)
		let classC = String(self.classCode, radix: 16, uppercase: true)
		return "DeviceConfig(vendor=0x\(vendor), device=0x\(device), class=0x\(classC))"
	}
}

// MARK: - CustomStringConvertible
/*extension DeviceConfig: CustomStringConvertible {
	var description: String {
		let vendor = String(self.vendorID, radix: 16, uppercase: true)
		let device = String(self.deviceID, radix: 16, uppercase: true)
		let classC = String(self.classCode, radix: 16, uppercase: true)
		return "DeviceConfig(vendor=0x\(vendor), device=0x\(device), class=0x\(classC))"
	}
}*/

