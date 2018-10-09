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

	func process(from: Device, to: Device, queue: Int) {
		let rx = from.receiveQueues[queue]
		let tx = to.transmitQueues[queue]

		rx.processBatch()
		let packets = rx.fetchAvailablePackets()
		for packet in packets {
			packet.touch()
		}
		tx.addPackets(packets: packets)
		tx.processBatch()
	}

	func loop() {
		var nextTime: DispatchTime = .now() + .seconds(1)
		let finalTime: DispatchTime = .now() + .seconds(30)

		while(finalTime > .now()) {
			for idx in 0..<queueCount {
				let intIdx = Int(idx)

				process(from: source, to: sink, queue: intIdx)
				process(from: sink, to: source, queue: intIdx)
			}
//			Log.log("Source: \(self.source.fetchStats())", level: .info, component: "app")
//			Log.log("Sink:   \(self.sink.fetchStats())", level: .info, component: "app")
//			usleep(1 * 1000 * 1000)
			let time: DispatchTime = .now()
			if(time > nextTime) {
				let statsA = self.source.readAndResetStats()
				let statsB = self.source.readAndResetStats()
				Log.log("A \(statsA.formatted(interval: 1.0))", level: .info, component: "app")
				Log.log("B \(statsB.formatted(interval: 1.0))", level: .info, component: "app")
				nextTime = .now() + .seconds(1)
			}
		}
	}
}
