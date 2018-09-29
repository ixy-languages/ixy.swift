//
//  DeviceStats.swift
//  ixy
//
//  Created by Thomas Günzel on 29.09.2018.
//

import Foundation

struct DeviceStats {
	struct LineStats {
		var packets: UInt32
		var bytes: UInt64

		static let zero = LineStats()

		init(packets: UInt32 = 0, bytes: UInt64 = 0) {
			self.packets = packets
			self.bytes = bytes
		}
	}

	var transmitted: LineStats
	var received: LineStats

	init(transmitted: LineStats = LineStats(), received: LineStats = LineStats()) {
		self.transmitted = transmitted
		self.received = received
	}

	init(transmittedPackets: UInt32, transmittedBytes: UInt64, receivedPackets: UInt32, receivedBytes: UInt64) {
		self.transmitted = LineStats(packets: transmittedPackets, bytes: transmittedBytes)
		self.received = LineStats(packets: receivedPackets, bytes: receivedBytes)
	}
}

func +=(_ lhs: inout DeviceStats.LineStats, rhs: DeviceStats.LineStats) {
	lhs.packets += rhs.packets
	lhs.bytes += rhs.bytes
}

func +=(_ lhs: inout DeviceStats, rhs: DeviceStats) {
	lhs.transmitted += rhs.transmitted
	lhs.received += rhs.received
}

func +(_ lhs: DeviceStats.LineStats, rhs: DeviceStats.LineStats) -> DeviceStats.LineStats {
	return DeviceStats.LineStats(packets: lhs.packets + rhs.packets, bytes: lhs.bytes + rhs.bytes)
}

func +(_ lhs: DeviceStats, rhs: DeviceStats) -> DeviceStats {
	return DeviceStats(transmitted: (lhs.transmitted + rhs.transmitted), received: (lhs.received + rhs.received))
}
