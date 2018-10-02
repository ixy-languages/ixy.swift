//
//  Driver+Queues.swift
//  ixy
//
//  Created by Thomas Günzel on 02.10.2018.
//

import Foundation

extension Driver {
	internal func start(queue: ReceiveQueue) {
		let index = UInt32(queue.index)
		let rxdctl = IXGBE_RXDCTL(index)
		self[rxdctl] |= IXGBE_RXDCTL_ENABLE
		wait(until: rxdctl, didSetMask: IXGBE_RXDCTL_ENABLE)

		self[IXGBE_RDH(index)] = 0
		self[IXGBE_RDT(index)] = UInt32(queue.descriptors.count - 1)
	}

	internal func start(queue: TransmitQueue) {
		let index = UInt32(queue.index)

		self[IXGBE_TDH(index)] = 0
		self[IXGBE_TDT(index)] = 0

		let txdctl = IXGBE_TXDCTL(index)
		self[txdctl] |= IXGBE_TXDCTL_ENABLE
		wait(until: txdctl, didSetMask: IXGBE_TXDCTL_ENABLE)
	}

	internal func update(queue: ReceiveQueue, tailIndex: UInt32) {
		self[IXGBE_RDT(UInt32(queue.index))] = tailIndex
	}

	internal func update(queue: TransmitQueue, tailIndex: UInt32) {
		self[IXGBE_TDT(UInt32(queue.index))] = tailIndex
	}
}
