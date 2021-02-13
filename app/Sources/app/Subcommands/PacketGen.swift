//
//  PacketGen.swift
//  app
//
//  Created by Thomas Günzel on 16.10.2018.
//

import Foundation
import ixy

class PacketGen: Subcommand {
	static let usage: String = "[device1]"

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
		while(true) {
			var tmpReceiveQueue = device.receiveQueues[0]
			let packets = tmpReceiveQueue.fetchAvailablePackets()

			if packets.count > 0 {
				Log.log("Got \(packets.count) packets", level: .info, component: "app")
			}
			
			var tx = device.transmitQueues[0]
			guard let packet = tx.createDummyPacket() else {
				fatalError("no packet available")
			}
			var tmpPacket = [packet]
			_ = tx.transmit(&tmpPacket)

			sleep(1)
		}
	}
}
