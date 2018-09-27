//
//  Config.swift
//  app
//
//  Created by Thomas Günzel on 25.09.2018.
//

import Foundation

internal class DeviceConfig: File {
	internal init?(address: String) {
		let path = Constants.pcieBasePath + address + "/config"
		super.init(path: path, flags: O_RDONLY)
	}

	var vendorID: UInt16 {
		return (try? self.read(offset: 0x00)) ?? 0
	}

	var deviceID: UInt16 {
		return (try? self.read(offset: 0x02)) ?? 0
	}

	var classCode: UInt32 {
		var code: UInt32
		do {
			// Datasheet P755
			// Register at 0x08 = [RevID:8][ClassCode:24]
			// -> read from 0x08 but discard first 8 bits
			try code = self.read(offset: 0x08)
			code = (code & 0x00FFFFFF)
		} catch {
			code = 0
		}
		return code
	}
}
