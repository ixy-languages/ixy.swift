//
//  Simple.swift
//  app
//
//  Created by Thomas Günzel on 09.10.2018.
//

import Foundation
import ixy

class Simple {
	private let device: Device
	private var stats: DeviceStats
	private var nextTime: DispatchTime

	init(address: String) throws {
		self.device = try Device(address: address)
		self.stats = DeviceStats.zero
		self.nextTime = DispatchTime.now()
	}

	func loop() {
		nextTime = .now() + .seconds(1)
		while(true) {
			device.receiveQueues[0].processBatch()
			let packets = device.receiveQueues[0].fetchAvailablePackets()
			//Log.log("got \(packets.count) packets", level: .info, component: "app")
			device.transmitQueues[0].addPackets(packets: packets)
			device.transmitQueues[0].processBatch()
//			sleep(1)

			let time: DispatchTime = .now()
			if(time > nextTime) {
				let newStats = device.readAndResetStats()
				Log.log("\(newStats.formatted(interval: 1.0))", level: .info, component: "app")
				nextTime = .now() + .seconds(1)

			}

		}
	}
}

extension Float {
	static let magnitudes = ["","k","M","G","T"]
	func formatted(baseUnit: String = "") -> String {
		var nextMagnitudes = Float.magnitudes
		var value = self
		while nextMagnitudes.count > 0 {
			let mag = nextMagnitudes.removeFirst()
			if value <= 1024.0 {
				let format = "%4.01f \(mag)\(baseUnit)"
				return String(format: format, value)
			} else {
				value /= 1024.0
			}
		}
		return "\(self) \(baseUnit)"
	}
}

extension DeviceStats.LineStats {
	func perSecond(interval: Float) -> (Float, Float) {
		return (Float(self.packets) / interval, Float(self.bytes) / interval)
	}

	func formatted(interval: Float) -> String {
		let (packetsPerSecond, bytesPerSecond) = self.perSecond(interval: interval)
		let bitsPerSecond = (bytesPerSecond * 8.0) + (packetsPerSecond * 20 * 8)
		return "\(bitsPerSecond.formatted(baseUnit: "bits/s")), \(packetsPerSecond.formatted(baseUnit: "pkgs/s"))"
	}
}

extension DeviceStats {
	func formatted(interval: Float) -> String {
		return "TX: \(transmitted.formatted(interval: interval))  RX: \(received.formatted(interval: interval))"
	}
}
