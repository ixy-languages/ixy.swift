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
	var overallStatsA: DeviceStats = .zero
	var overallStatsB: DeviceStats = .zero

	var lost: Int = 0
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
		let sentPackets = tx.transmit2(packets, freeUnused: true)
		//Log.log("newly lost \(newlyLost)", level: .info, component: "app")
		lost += (packets.count - sentPackets)

//		tx.addPackets(packets: packets)
//		tx.processBatch()
	}

	func loop() {
		var nextTime: DispatchTime = .now() + .seconds(1)
		let finalTime: DispatchTime = .now() + .seconds(10)

		while(finalTime > .now()) {
			process(from: source, to: sink, queue: 0)
			process(from: sink, to: source, queue: 0)
//			Log.log("Source: \(self.source.fetchStats())", level: .info, component: "app")
//			Log.log("Sink:   \(self.sink.fetchStats())", level: .info, component: "app")
//			usleep(1 * 1000 * 1000)
			let time: DispatchTime = .now()
			if(time > nextTime) {
				let statsA = self.source.readAndResetStats()
				overallStatsA += statsA
				let statsB = self.sink.readAndResetStats()
				overallStatsB += statsB
//				Log.log("A \(statsA.formatted(interval: 1.0))", level: .info, component: "app")
				Log.log("[A]: \(overallStatsA)", level: .info, component: "app")

//				Log.log("Lost: \(lost)", level: .info, component: "app")
				Log.log("[A] RX: \(source.receiveQueues[0].receivedPackets)\tTX: \(source.transmitQueues[0].sentPackets)", level: .info, component: "app")
				Log.log("[B]: \(overallStatsB)", level: .info, component: "app")
				Log.log("[B] RX: \(sink.receiveQueues[0].receivedPackets)\tTX: \(sink.transmitQueues[0].sentPackets)", level: .info, component: "app")
//				Log.log("B \(statsB.formatted(interval: 1.0))", level: .info, component: "app")
				nextTime = .now() + .seconds(1)
				if(time > finalTime) {
					exit(1)
				}
			}
		}
	}
}
