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
		cleanUpOld()

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

	private func cleanUpOld() {
		// iterate over descriptors and clean up, adjusting the head index
		while cleanUp(descriptor: descriptors[headIndex]) {
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

	public func createDummyPacket() -> DMAMempool.Pointer? {
		guard let dummy = self.packetMempool.getFreePointer() else { return nil }
		dummy.size = c_ixy_dbg_packet_size()
		let ptr = dummy.entry.pointer.virtual
		c_ixy_dbg_fill_packet(ptr)
		return dummy
	}
}

