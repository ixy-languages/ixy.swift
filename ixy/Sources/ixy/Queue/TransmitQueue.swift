import c_ixy

public class TransmitQueue: Queue {
	internal var headIndex: Int = 0
	internal var remainingPackets: [DMAMempool.Pointer] = []
	public var lostPackets: Int = 0
	public var sentPackets: Int = 0

	override func start() {
		Log.debug("starting \(self.index)", component: .tx)
		for descriptor in descriptors {
			descriptor.cleanUp()
		}
		driver.start(queue: self)
	}

	override public func processBatch() {
		cleanUpOld()
		transmitPackets()
	}

	private func cleanUpOld() {
		//Log.debug("cleaning up old", component: .tx)
		while cleanUp(descriptor: descriptors[headIndex]) {
			headIndex ++< descriptors.count
		}
	}

	private func cleanUp(descriptor: Descriptor) -> Bool {
		guard headIndex != tailIndex else {
			Log.debug("head \(headIndex) = tail \(tailIndex). cleanup done", component: .tx)
			return false
		}
		guard descriptor.transmitted else {
			Log.debug("[\(descriptor.packetPointer?.id ?? -1)] packet not yet transmitted", component: .tx)
			return false
		}
		Log.debug("[\(descriptor.packetPointer?.id ?? -1)] packet was transmitted", component: .tx)
		descriptor.cleanUpTransmitted()
		sentPackets += 1
		return true
	}

	private func transmitPackets() {
		guard remainingPackets.isEmpty == false else { return }
		var packetIndex: Int = 0
		while transmitNext(packetIndex) {
			tailIndex ++< descriptors.count
			packetIndex += 1
		}
		if packetIndex > 0, self.remainingPackets.count != 0 { self.remainingPackets.removeFirst(packetIndex) }
		self.driver.update(queue: self, tailIndex: UInt32(tailIndex))
	}

	public func createDummyPacket() -> DMAMempool.Pointer? {
		guard let dummy = self.packageMempool.getFreePointer() else { return nil }
		dummy.size = c_ixy_dbg_packet_size()
		let ptr = dummy.entry.pointer.virtual
		c_ixy_dbg_fill_packet(ptr)
		return dummy
	}

	private func transmitNext(_ packetIndex: Int) -> Bool {
		var nextIndex: Int = tailIndex
		nextIndex ++< descriptors.count

		guard nextIndex != headIndex else {
			Log.debug("queue full \(index), discarding packets", component: .tx)
			for packet in self.remainingPackets {
				packet.free()
			}
			lostPackets += self.remainingPackets.count
			self.remainingPackets = []
			return false
		}
		guard packetIndex < self.remainingPackets.count else {
			Log.debug("no packets to transmit", component: .tx)
			return false
		}
		let packet = self.remainingPackets[packetIndex]

		self.descriptors[tailIndex].scheduleForTransmission(packetPointer: packet)
		Log.debug("[\(packet.id)] added packet to transmit", component: .tx)

		return true
	}

	public func transmit(_ packets: [DMAMempool.Pointer], freeUnused: Bool = true) -> Int {
		cleanUpOld()

		var nextIndex: Int = tailIndex
		let oldIndex: Int = tailIndex

		var txCount: Int = 0
		for packet in packets {
			nextIndex ++< descriptors.count
			guard nextIndex != headIndex else {
				//Log.info("queue full \(index), discarding packets", component: .tx)
				break
			}
			self.descriptors[tailIndex].scheduleForTransmission(packetPointer: packet)
			txCount += 1
			tailIndex ++< descriptors.count
		}

		if oldIndex != tailIndex {
			self.driver.update(queue: self, tailIndex: UInt32(tailIndex))
		}

		//Log.info("txCount \(txCount) \(packets.count)", component: .tx)
		if freeUnused && txCount < packets.count {
			var freed: Int = 0
			for packet in packets[txCount..<packets.count] {
				packet.free()
				freed += 1
			}
			//Log.info("did free \(freed)", component: .tx)
		}

		return txCount
	}

	override func process(descriptor: Descriptor) -> Bool {
		return false
	}

}

