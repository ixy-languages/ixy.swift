//
//  Forward.swift
//  app
//
//  Created by Thomas Günzel on 09.10.2018.
//

import Foundation
import ixy

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

class Forward: Subcommand {
	static let usage: String = "[device1] [device2]"

	let device1: Device
	let device2: Device
	let batchSize: Int?
	var overallStats1: DeviceStats = .zero
	var overallStats2: DeviceStats = .zero

	var lost: Int = 0

	enum Error: Swift.Error {
		case sameDevice
	}

	init(device1Address: PCIAddress, device2Address: PCIAddress, batchSize: Int? = nil) throws {
		// check if it's the same device
		guard device1Address != device2Address else { throw Error.sameDevice }

		Log.log("Starting forward from \(device1Address) to \(device2Address)", level: .info, component: "app")

		// init devices
		self.device1 = try Device(address: device1Address, receiveQueues: 1, transmitQueues: 1)
		self.device2 = try Device(address: device2Address, receiveQueues: 1, transmitQueues: 1)
		self.batchSize = batchSize
	}

	// Subcommand init implementation
	required convenience init(arguments: [String]) throws {
		guard arguments.count >= 2 else { throw SubcommandError.notEnoughArguments }

		// parse addresses and init self
		let device1Address = try PCIAddress(from: arguments[0])
		let device2Address = try PCIAddress(from: arguments[1])
		let batchSize = arguments.count >= 3 ? Int(arguments[2]) : nil
		try self.init(device1Address: device1Address, device2Address: device2Address, batchSize: batchSize)
	}

	// process/forward from -> to device using a specific queue (currently the queue is always 0)
	private func process(from: Device, to: Device, queue: Int) {
		// get queues
		let rx = from.receiveQueues[queue]
		let tx = to.transmitQueues[queue]

		// receive packets
		let packets = rx.fetchAvailablePackets(limit: batchSize)
		for packet in packets {
			// touch each packet
			packet.touch()
		}

		// transmit packets
		let sentPackets = tx.transmit(packets, freeUnused: true)

		// keep track of lost packets due if not enough tx descriptors are available
		lost += (packets.count - sentPackets)
	}

	func loop() {
		var nextTime: DispatchTime = .now() + .seconds(1)
		var lastTime: DispatchTime = .now()
		let finalTime: DispatchTime = .now() + .seconds(10)
		var counter: UInt = 0
		var continueLoop: Bool = true
		let device1String: String = "\(device1.address)"
		let device2String: String = "\(device1.address)"

		while continueLoop {
			// forward the packets
			process(from: device1, to: device2, queue: 0)
			process(from: device2, to: device1, queue: 0)

			// check if printing is necessary
			counter += 1
			if(counter > 0xFFF) {
				let time: DispatchTime = .now()
				if(time > nextTime) {
					let stats1 = self.device1.readAndResetStats()
					overallStats1 += stats1
					let stats2 = self.device2.readAndResetStats()
					overallStats2 += stats2

					let diff: Float = Float(time.uptimeNanoseconds - lastTime.uptimeNanoseconds) / (1_000_000_000 as Float)
//					Log.log("[1]: \(stats1.formatted(interval: diff))", level: .info, component: "app")
//					Log.log("[2]: \(stats2.formatted(interval: diff))", level: .info, component: "app")
					print("[\(device1String)] RX: \(stats1.received.c_ixy_format(interval: diff))")
					print("[\(device1String)] TX: \(stats1.transmitted.c_ixy_format(interval: diff))")
					print("[\(device2String)] RX: \(stats2.received.c_ixy_format(interval: diff))")
					print("[\(device2String)] TX: \(stats2.transmitted.c_ixy_format(interval: diff))")

					fflush(stdout)


					lastTime = .now()
					nextTime = .now() + .seconds(1)
				}
				if time > finalTime {
					continueLoop = false
				}
				counter = 0
			}
		}
		Log.log("--- Overall ---", level: .info, component: "app")
		Log.log("[1]: \(overallStats1.formatted())", level: .info, component: "app")
		Log.log("[2]: \(overallStats2.formatted())", level: .info, component: "app")
	}
}


