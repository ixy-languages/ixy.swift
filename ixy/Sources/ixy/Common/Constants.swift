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
}
