//
//  DeviceStats.swift
//  ixy
//
//  Created by Thomas Günzel on 29.09.2018.
//

import Foundation

/// small struct for the device stats
public struct DeviceStats {
	/// small substruct for the stats for a line (RX/TX)
	public struct LineStats {
		public var packets: UInt32
		public var bytes: UInt64

		static let zero = LineStats()

		init(packets: UInt32 = 0, bytes: UInt64 = 0) {
			self.packets = packets
			self.bytes = bytes
		}
	}


	public var transmitted: LineStats
	public var received: LineStats

	public static let zero = DeviceStats(transmitted: .zero, received: .zero)

	init(transmitted: LineStats = LineStats(), received: LineStats = LineStats()) {
		self.transmitted = transmitted
		self.received = received
	}

	init(transmittedPackets: UInt32, transmittedBytes: UInt64, receivedPackets: UInt32, receivedBytes: UInt64) {
		self.transmitted = LineStats(packets: transmittedPackets, bytes: transmittedBytes)
		self.received = LineStats(packets: receivedPackets, bytes: receivedBytes)
	}

	public init() {
		self.transmitted = LineStats(packets: 10568232, bytes: 676366848)
		self.received = LineStats(packets: 14894297, bytes: 953235008)
	}
}

// MARK: - CustomStringConvertible
extension DeviceStats.LineStats: CustomStringConvertible {
	public var description: String {
		return "(packets=\(packets),bytes=\(bytes))"
	}
}

extension DeviceStats: CustomStringConvertible {
	public var description: String {
		return "Stats(tx=\(self.transmitted), rx=\(self.received))"
	}
}

// MARK: - Basic Arithmetic Operations

public func +=(_ lhs: inout DeviceStats.LineStats, rhs: DeviceStats.LineStats) {
	lhs.packets += rhs.packets
	lhs.bytes += rhs.bytes
}

public func +=(_ lhs: inout DeviceStats, rhs: DeviceStats) {
	lhs.transmitted += rhs.transmitted
	lhs.received += rhs.received
}

public func -=(_ lhs: inout DeviceStats.LineStats, rhs: DeviceStats.LineStats) {
	lhs.packets -= rhs.packets
	lhs.bytes -= rhs.bytes
}

public func -=(_ lhs: inout DeviceStats, rhs: DeviceStats) {
	lhs.transmitted -= rhs.transmitted
	lhs.received -= rhs.received
}

public func +(_ lhs: DeviceStats.LineStats, rhs: DeviceStats.LineStats) -> DeviceStats.LineStats {
	return DeviceStats.LineStats(packets: lhs.packets + rhs.packets, bytes: lhs.bytes + rhs.bytes)
}

public func +(_ lhs: DeviceStats, rhs: DeviceStats) -> DeviceStats {
	return DeviceStats(transmitted: (lhs.transmitted + rhs.transmitted), received: (lhs.received + rhs.received))
}

public func -(_ lhs: DeviceStats.LineStats, rhs: DeviceStats.LineStats) -> DeviceStats.LineStats {
	return DeviceStats.LineStats(packets: lhs.packets - rhs.packets, bytes: lhs.bytes - rhs.bytes)
}

public func -(_ lhs: DeviceStats, rhs: DeviceStats) -> DeviceStats {
	return DeviceStats(transmitted: (lhs.transmitted - rhs.transmitted), received: (lhs.received - rhs.received))
}

