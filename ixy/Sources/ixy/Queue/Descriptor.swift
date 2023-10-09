//
//  DescriptorRing.swift
//  app
//
//  Created by Thomas Günzel on 26.09.2018.
//

import Foundation

struct Descriptor {
	internal let queuePointer: UnsafeMutablePointer<UInt64>
	internal var packetPointer: DMAMempool.Pointer?
	internal var packetMempool: DMAMempool

	init(queuePointer: UnsafeMutablePointer<UInt64>, mempool: DMAMempool) {
		self.queuePointer = queuePointer
		self.packetMempool = mempool
	}
}
