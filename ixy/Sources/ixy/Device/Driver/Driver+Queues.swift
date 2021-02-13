//
//  Driver+Queues.swift
//  ixy
//
//  Created by Thomas Günzel on 02.10.2018.
//

import Foundation

extension Driver {
	internal mutating func start(receiveQueue: ReceiveQueue) {
		let index = UInt32(receiveQueue.queue.index)
		let rxdctl = IXGBE_RXDCTL(index)
		
		self[rxdctl] |= IXGBE_RXDCTL_ENABLE
		wait(until: rxdctl, didSetMask: IXGBE_RXDCTL_ENABLE)

		self[IXGBE_RDH(index)] = 0
		//self[IXGBE_RDT(index)] = UInt32(queue.descriptors.count - 1)
		self.update(receiveQueue: receiveQueue, tailIndex: UInt32(receiveQueue.queue.descriptors.count - 1))
	}

	func getHeadIndex(receiveQueue: ReceiveQueue) -> UInt32 {
		return self[IXGBE_RDH(UInt32(receiveQueue.queue.index))]
	}

	internal mutating func start(transmitQueue: TransmitQueue) {
		let index = UInt32(transmitQueue.queue.index)

		self[IXGBE_TDH(index)] = 0
		self[IXGBE_TDT(index)] = 0

		let txdctl = IXGBE_TXDCTL(index)
		self[txdctl] |= IXGBE_TXDCTL_ENABLE
		wait(until: txdctl, didSetMask: IXGBE_TXDCTL_ENABLE)
	}

	internal mutating func update(receiveQueue: ReceiveQueue, tailIndex: UInt32) {
		self[IXGBE_RDT(UInt32(receiveQueue.queue.index))] = tailIndex
	}

	internal mutating func update(transmitQueue: TransmitQueue, tailIndex: UInt32) {
		self[IXGBE_TDT(UInt32(transmitQueue.queue.index))] = tailIndex
	}
}
