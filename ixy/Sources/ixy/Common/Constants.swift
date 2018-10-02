//
//  Constants.swift
//  app
//
//  Created by Thomas Günzel on 25.09.2018.
//

import Foundation

struct Constants {
	internal static let pcieBasePath: String = "/sys/bus/pci/devices/"
	internal static let pagemapPath: String = "/proc/self/pagemap"

	internal static let hugepagePath: String = "/mnt/huge/"
	internal static let hugepageBits: Int = 21
	internal static let hugepagePageSize: Int = (1 << 21)

	struct Device {
		internal static let vendorID: UInt16 = 0x8086
		internal static let maxPacketSize: UInt = 2048
	}

	struct Queue {
		internal static let ringEntryCount: UInt = 512
		internal static let ringEntrySize: UInt = UInt(MemoryLayout<UInt64>.size * 2)
		internal static let ringSizeBytes: UInt = { return Queue.ringEntryCount * Queue.ringEntrySize} ()
	}
}
