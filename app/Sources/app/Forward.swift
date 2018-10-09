//
//  Forward.swift
//  app
//
//  Created by Thomas Günzel on 09.10.2018.
//

import Foundation
import ixy

class Forward {
	let source: Device
	let sink: Device
	let queueCount: UInt

	enum Error: Swift.Error {
		case sameDevice
	}

	init(sourceAddress: String, sinkAddress: String, queueCount: UInt = 1) throws {
		guard sourceAddress != sinkAddress else { throw Error.sameDevice }
		Log.log("Starting forward from \(sourceAddress) to \(sinkAddress)", level: .info, component: "app")
		
		self.queueCount = queueCount
		self.source = try Device(address: sourceAddress, receiveQueues: queueCount, transmitQueues: 1)
		self.sink = try Device(address: sinkAddress, receiveQueues: 1, transmitQueues: queueCount)
	}

	func loop(sleep: Int = 1 * 1000 * 1000) {
		for idx in 0..<queueCount {
			let intIdx = Int(idx)
			let rx = self.source.receiveQueues[intIdx]
			let tx = self.sink.transmitQueues[intIdx]

			rx.processBatch()
			let packets = rx.fetchAvailablePackets()
			tx.addPackets(packets: packets)
			tx.processBatch()
		}
		usleep(1 * 1000 * 1000)
	}
}
