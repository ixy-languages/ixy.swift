//
//  Simple.swift
//  app
//
//  Created by Thomas Günzel on 09.10.2018.
//

import Foundation
import ixy

class Simple: Subcommand {
	static let usage: String = "[device]"

	private let device: Device
	private var stats: DeviceStats
	private var nextTime: DispatchTime

	init(address: PCIAddress) throws {
		self.device = try Device(address: address, receiveQueues: 1, transmitQueues: 1)
		self.stats = device.readAndResetStats()
		self.nextTime = DispatchTime.now()
	}

	required convenience init(arguments: [String]) throws {
		guard arguments.count >= 1 else { throw SubcommandError.notEnoughArguments }
		let address = try PCIAddress(from: arguments[0])
		try self.init(address: address)
	}

	func loop() {
		nextTime = .now() + .seconds(1)
		while(true) {
			var tmpReceiveQueue = device.receiveQueues[0]
			var packets = tmpReceiveQueue.fetchAvailablePackets()

			if packets.count > 0 {
				Log.log("Got \(packets.count) packets", level: .info, component: "app")
				for packet in packets {
					print("Dumping Packet \(packet.packetData?.baseAddress?.debugDescription ?? "???")")
					packet.dump()
				}
			}

			var tmpTransmitQueue = device.transmitQueues[0]
			_ = tmpTransmitQueue.transmit(&packets)

			sleep(1)

			let time: DispatchTime = .now()
			if(time > nextTime) {
				let newStats = device.readAndResetStats()
				Log.log("\(newStats.formatted(interval: 1.0))", level: .info, component: "app")
				nextTime = .now() + .seconds(1)

			}

		}
	}
}
