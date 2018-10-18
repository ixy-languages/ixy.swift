
public final class ReceiveQueue : Queue {
	private var availablePackets: [DMAMempool.Pointer] = []
	private var headIndex: Int = 0

	public var receivedPackets: Int = 0

	override public func processBatch() {
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

	override func process(descriptor: Descriptor) -> Bool {
		switch descriptor.receivePacket() {
		case .notReady:
			Log.debug("package not ready", component: .rx)
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

	public func fetchAvailablePackets() -> [DMAMempool.Pointer] {
		let packets = self.availablePackets
		self.availablePackets = []
		return packets
	}


	override func start() {
		Log.debug("starting \(self.index)", component: .rx)
		for descriptor in self.descriptors {
			descriptor.prepareForReceiving()
		}
//		self.tailIndex = self.descriptors.count - 1
		driver.start(queue: self)
	}
}

