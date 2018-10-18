//
//  PacketGen.swift
//  app
//
//  Created by Thomas Günzel on 16.10.2018.
//

import Foundation
import ixy

class PacketGen {
	private let device: Device
	private var stats: DeviceStats
	private var nextTime: DispatchTime

	init(address: String) throws {
		self.device = try Device(address: address, receiveQueues: 1, transmitQueues: 1)
		self.stats = device.readAndResetStats()
		self.nextTime = DispatchTime.now()
	}

	func loop() {
		while(true) {
			device.receiveQueues[0].processBatch()
			let packets = device.receiveQueues[0].fetchAvailablePackets()

			if packets.count > 0 {
				print("got \(packets.count) packets!")
			}
			//Log.log("got \(packets.count) packets", level: .info, component: "app")
			let tx = device.transmitQueues[0]
			guard let packet = tx.createDummyPacket() else {
				fatalError("no packet available")
			}
			tx.addPackets(packets: [packet])
			tx.processBatch()

			sleep(1)
		}
	}
}
