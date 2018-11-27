import c_ixy

public final class TransmitQueue: Queue {
	public var lostPackets: Int = 0
	public var sentPackets: Int = 0

	/// adds the packets to the transmit buffer
	///
	/// - Parameters:
	///   - packets: the packets to add
	///   - freeUnused: if true, packets that can't be added will be automatically freed
	/// - Returns: the number of added packets
	public func transmit(_ packets: [DMAMempool.Pointer], freeUnused: Bool = true) -> Int {
		#if USE_BATCH_TX_CLEAN
		cleanUpBatch()
		#else
		cleanUp()
		#endif

		var nextIndex: Int = tailIndex
		let oldIndex: Int = tailIndex

		var txCount: Int = 0
		for packet in packets {
			nextIndex ++< descriptors.count
			guard nextIndex != headIndex else {
				break
			}
			self.descriptors[tailIndex].scheduleForTransmission(packetPointer: packet)
			txCount += 1
			tailIndex ++< descriptors.count
		}

		if oldIndex != tailIndex {
			self.driver.update(queue: self, tailIndex: UInt32(tailIndex))
		}

		if freeUnused && txCount < packets.count {
			var freed: Int = 0
			for packet in packets[txCount..<packets.count] {
				packet.free()
				freed += 1
			}
		}

		return txCount
	}

	override func start() {
		Log.debug("Starting \(self.index)", component: .tx)
		for descriptor in descriptors {
			descriptor.cleanUp()
		}
		driver.start(queue: self)
	}

	private func cleanUp() {
		// iterate over descriptors and clean up, adjusting the head index
		while cleanUp(descriptor: descriptors[headIndex]) {
			headIndex ++< descriptors.count
		}
	}

	private func cleanUpBatch() {
		while true {
			var cleanable: Int = tailIndex - headIndex
			if cleanable < 0 {
				cleanable = descriptors.count + cleanable
			}
			if cleanable < 32 {
				break
			}
			var cleanup_to: Int = headIndex + 32 - 1
			if cleanup_to >= descriptors.count {
				cleanup_to -= descriptors.count
			}

			if descriptors[cleanup_to].transmitted {
				var i: Int = headIndex
				while true {
					descriptors[i].cleanUpTransmitted()
					if i == cleanup_to {
						break
					}
					i ++< descriptors.count
				}
				sentPackets += 32
			} else {
				break
			}
			headIndex = cleanup_to
			headIndex ++< descriptors.count
		}
	}

	private func cleanUp(descriptor: Descriptor) -> Bool {
		// check if head < tail
		guard headIndex != tailIndex else {
			Log.debug("head \(headIndex) = tail \(tailIndex). cleanup done", component: .tx)
			return false
		}
		// check if transmitted
		guard descriptor.transmitted else {
			Log.debug("[\(descriptor.packetPointer?.id ?? -1)] packet not yet transmitted", component: .tx)
			return false
		}
		// cleanup and update stats
		Log.debug("[\(descriptor.packetPointer?.id ?? -1)] packet was transmitted", component: .tx)
		descriptor.cleanUpTransmitted()
		sentPackets += 1
		return true
	}
}

// Dummy Packet Creation

extension TransmitQueue {
	// hardcoded packet, taken  from ixy (c-version) as the payload doesn't matter that much and is static
	private static let dummyPacketData: [UInt8] = [
		 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x11, 0x12,
		 0x13, 0x14, 0x15, 0x16, 0x08, 0x00, 0x45, 0x00,
		 0x00, 0x2e, 0x00, 0x00, 0x00, 0x00, 0x40, 0x11,
		 0x66, 0xbd, 0x0a, 0x00, 0x00, 0x01, 0x0a, 0x00,
		 0x00, 0x02, 0x00, 0x2a, 0x05, 0x39, 0x00, 0x1a,
		 0x00, 0x00, 0x69, 0x78, 0x79, 0x00, 0x00, 0x00,
		 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		 0x00, 0x00, 0x00, 0x00]

	public func createDummyPacket() -> DMAMempool.Pointer? {
		guard let dummy = self.packetMempool.getFreePointer() else { return nil }
		let size = TransmitQueue.dummyPacketData.count
		let ptr = dummy.entry.pointer.virtual

		dummy.size = UInt16(size)
		ptr.copyMemory(from: TransmitQueue.dummyPacketData, byteCount: size)

		return dummy
	}
}

