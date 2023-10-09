
public struct TransmitQueue {
	var queue : Queue
	public var lostPackets: Int = 0
	public var sentPackets: Int = 0

	init(index: UInt, memory: MemoryMap, packetMempool: DMAMempool, descriptorCount: UInt, driver: Driver) throws {
		try self.queue = Queue(index: index, memory: memory, packetMempool: packetMempool, descriptorCount: descriptorCount, driver: driver)
	}

	/// adds the packets to the transmit buffer
	///
	/// - Parameters:
	///   - packets: the packets to add
	///   - freeUnused: if true, packets that can't be added will be automatically freed
	/// - Returns: the number of added packets
	public mutating func transmit(_ packets: inout [DMAMempool.Pointer], freeUnused: Bool = true) -> Int {
		#if USE_BATCH_TX_CLEAN
		cleanUpBatch()
		#else
		cleanUp()
		#endif

		var nextIndex: Int = self.queue.tailIndex
		let oldIndex: Int = self.queue.tailIndex

		var txCount: Int = 0
		for packet in packets {
			nextIndex ++< self.queue.descriptors.count
			guard nextIndex != self.queue.headIndex else {
				break
			}
			self.queue.descriptors[self.queue.tailIndex].scheduleForTransmission(packetPointer: packet)
			txCount += 1
			self.queue.tailIndex ++< self.queue.descriptors.count
		}

		if oldIndex != self.queue.tailIndex {
			self.queue.driver.update(transmitQueue: self, tailIndex: UInt32(self.queue.tailIndex))
		}

		if freeUnused && txCount < packets.count {
			var freed: Int = 0
			for indx in txCount..<packets.count {
				packets[indx].free()
				freed += 1
			}
		}

		return txCount
	}

	mutating func start() {
		Log.debug("Starting \(self.queue.index)", component: .tx)
		for indx in 0..<self.queue.descriptors.count {
			self.queue.descriptors[indx].cleanUp()
		}
		self.queue.driver.start(transmitQueue: self)
	}

	private mutating func cleanUp() {
		// iterate over descriptors and clean up, adjusting the head index
		//var tmpDescriptor = self.queue.descriptors[self.queue.headIndex]
		/*while cleanUp(descriptor: &tmpDescriptor) {
			self.queue.headIndex ++< self.queue.descriptors.count
		}*/
		while cleanUp(index: self.queue.headIndex) {
			self.queue.headIndex ++< self.queue.descriptors.count
		}
	}

	private mutating func cleanUpBatch() {
		while true {
			var cleanable: Int = self.queue.tailIndex - self.queue.headIndex
			if cleanable < 0 {
				cleanable = self.queue.descriptors.count + cleanable
			}
			if cleanable < 32 {
				break
			}
			var cleanup_to: Int = self.queue.headIndex + 32 - 1
			if cleanup_to >= self.queue.descriptors.count {
				cleanup_to -= self.queue.descriptors.count
			}

			if self.queue.descriptors[cleanup_to].transmitted {
				var i: Int = self.queue.headIndex
				while true {
					self.queue.descriptors[i].cleanUpTransmitted()
					if i == cleanup_to {
						break
					}
					i ++< self.queue.descriptors.count
				}
				sentPackets += 32
			} else {
				break
			}
			self.queue.headIndex = cleanup_to
			self.queue.headIndex ++< self.queue.descriptors.count
		}
	}

	private mutating func cleanUp(index: Int) -> Bool {
		// check if head < tail
		guard self.queue.headIndex != self.queue.tailIndex else {
			Log.debug("head \(self.queue.headIndex) = tail \(self.queue.tailIndex). cleanup done", component: .tx)
			return false
		}
		// check if transmitted
		guard self.queue.descriptors[index].transmitted else {
			Log.debug("[\(self.queue.descriptors[index].packetPointer?.id ?? -1)] packet not yet transmitted", component: .tx)
			return false
		}
		// cleanup and update stats
		Log.debug("[\(self.queue.descriptors[index].packetPointer?.id ?? -1)] packet was transmitted", component: .tx)
		self.queue.descriptors[index].cleanUpTransmitted()
		sentPackets += 1
		return true
	}

	private mutating func cleanUp(descriptor: inout Descriptor) -> Bool {
		// check if head < tail
		guard self.queue.headIndex != self.queue.tailIndex else {
			Log.debug("head \(self.queue.headIndex) = tail \(self.queue.tailIndex). cleanup done", component: .tx)
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

	static func withHugepageMemory(index: UInt, packetMempool: DMAMempool, descriptorCount: UInt, driver: Driver) throws -> TransmitQueue {
		let pageSize = (Int(descriptorCount) * MemoryLayout<Int64>.size * 2)
		let hugepage = try Hugepage(size: pageSize, requireContiguous: true)
		return try TransmitQueue(index: index, memory: hugepage.memoryMap, packetMempool: packetMempool, descriptorCount: descriptorCount, driver: driver)
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

	public mutating func createDummyPacket() -> DMAMempool.Pointer? {
		guard var dummy = self.queue.packetMempool.getFreePointer() else { return nil }
		let size = TransmitQueue.dummyPacketData.count
		let ptr = dummy.entry.pointer.virtual

		dummy.size = UInt16(size)
		ptr.copyMemory(from: TransmitQueue.dummyPacketData, byteCount: size)

		return dummy
	}
}

