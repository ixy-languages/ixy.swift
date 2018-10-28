//
//  Forward.swift
//  app
//
//  Created by Thomas Günzel on 09.10.2018.
//

import Foundation
import ixy

class Forward: Subcommand {
	static let usage: String = "[device1] [device2]"

	let device1: Device
	let device2: Device
	var overallStats1: DeviceStats = .zero
	var overallStats2: DeviceStats = .zero

	var lost: Int = 0

	enum Error: Swift.Error {
		case sameDevice
	}

	init(device1Address: PCIAddress, device2Address: PCIAddress,
		 receiveQueueCount: UInt = 1, transmitQueueCount: UInt = 1) throws {
		guard device1Address != device2Address else { throw Error.sameDevice }
		Log.log("Starting forward from \(device1Address) to \(device2Address)", level: .info, component: "app")
		
		self.device1 = try Device(address: device1Address, receiveQueues: receiveQueueCount, transmitQueues: transmitQueueCount)
		self.device2 = try Device(address: device2Address, receiveQueues: receiveQueueCount, transmitQueues: transmitQueueCount)
	}

	required convenience init(arguments: [String]) throws {
		guard arguments.count >= 2 else { throw SubcommandError.notEnoughArguments }
		let device1Address = try PCIAddress(from: arguments[0])
		let device2Address = try PCIAddress(from: arguments[1])
		try self.init(device1Address: device1Address, device2Address: device2Address)
	}

	func process(from: Device, to: Device, queue: Int) {
		let rx = from.receiveQueues[queue]
		let tx = to.transmitQueues[queue]

		rx.processBatch()
		let packets = rx.fetchAvailablePackets()
		for packet in packets {
			packet.touch()
		}
		let sentPackets = tx.transmit(packets, freeUnused: true)
		lost += (packets.count - sentPackets)
	}

	func loop() {
		var nextTime: DispatchTime = .now() + .seconds(1)
		var lastTime: DispatchTime = .now()
		let finalTime: DispatchTime = .now() + .seconds(10)

		while(finalTime > .now()) {
			process(from: device1, to: device2, queue: 0)
			process(from: device2, to: device1, queue: 0)

			let time: DispatchTime = .now()
			if(time > nextTime) {
				let stats1 = self.device1.readAndResetStats()
				overallStats1 += stats1
				let stats2 = self.device2.readAndResetStats()
				overallStats2 += stats2

				let diff: Float = Float(time.uptimeNanoseconds - lastTime.uptimeNanoseconds) / (1_000_000_000 as Float)
				Log.log("[1]: \(stats1.formatted(interval: diff))", level: .info, component: "app")
				Log.log("[2]: \(stats2.formatted(interval: diff))", level: .info, component: "app")

				lastTime = .now()
				nextTime = .now() + .seconds(1)
			}
		}
		Log.log("--- Overall ---", level: .info, component: "app")
		Log.log("[1]: \(overallStats1.formatted())", level: .info, component: "app")
		Log.log("[2]: \(overallStats2.formatted())", level: .info, component: "app")
	}
}


