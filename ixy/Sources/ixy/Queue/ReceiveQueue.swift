
public final class ReceiveQueue : Queue {
	private var availablePackets: [DMAMempool.Pointer] = []

	public var receivedPackets: Int = 0

	/// fetches available packet from the ring buffer and returns them
	///
	/// - Returns: array of packets
	public func fetchAvailablePackets() -> [DMAMempool.Pointer] {
		processBatch()
		let packets = self.availablePackets
		self.availablePackets = []
		return packets
	}

	func processBatch() {
		var lastIndex = tailIndex
		let lastRxIndex = tailIndex
		while process(descriptor: descriptors[tailIndex]) {
			lastIndex = tailIndex
			tailIndex ++< descriptors.count
		}
		if lastRxIndex != tailIndex {
			self.driver.update(queue: self, tailIndex: UInt32(lastIndex))
		}
	}

	func process(descriptor: Descriptor) -> Bool {
		switch descriptor.receivePacket() {
		case .notReady:
			Log.debug("Packet not ready", component: .rx)
			return false
		case .unknownError, .multipacket:
			// although there has been an error, in order to keep the queue from blocking
			receivedPackets += 1
			descriptor.prepareForReceiving()
			return true
		case .packet(let packet):
			// append the packet to our available packets buffer
			receivedPackets += 1
			availablePackets.append(packet)
			// prepare the descriptor for reuse -> fetch new packet buffer etc
			descriptor.prepareForReceiving()
			return true
		}
	}

	override func start() {
		Log.debug("Starting \(self.index)", component: .rx)
		for descriptor in self.descriptors {
			descriptor.prepareForReceiving()
		}
		driver.start(queue: self)
	}
}

