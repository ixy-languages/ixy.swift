
public class TransmitQueue: Queue {
	internal var headIndex: Int = 0
	internal var remainingPackets: [DMAMempool.Pointer] = []

	override func start() {
		Log.debug("starting \(self.index)", component: .tx)
		driver.start(queue: self)
	}

	override public func processBatch() {
		cleanUpOld()
		transmitPackets()
	}

	private func cleanUpOld() {
		while cleanUp(descriptor: descriptors[headIndex]) {
			headIndex ++< descriptors.count
		}
	}

	private func cleanUp(descriptor: Descriptor) -> Bool {
		guard headIndex != tailIndex else {
			Log.debug("head = tail. cleanup done", component: .tx)
			return false
		}
		guard descriptor.transmitted else {
			Log.debug("[\(descriptor.packetPointer?.id ?? -1)] packet not yet transmitted", component: .tx)
			return false
		}
//		Log.debug("[\(descriptor.packetPointer?.id ?? -1)] packet was transmitted", component: .tx)
		descriptor.cleanUpTransmitted()
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

	public func addPackets(packets: [DMAMempool.Pointer]) {
		self.remainingPackets.append(contentsOf: packets)
	}

	private func transmitNext(_ packetIndex: Int) -> Bool {
		var nextIndex: Int = tailIndex
		nextIndex ++< descriptors.count

		guard nextIndex != headIndex else {
			Log.debug("queue full \(index), discarding packets", component: .tx)
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

	override func process(descriptor: Descriptor) -> Bool {
		return false
	}

}

