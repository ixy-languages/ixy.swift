
public final class ReceiveQueue : Queue {
	private var availablePackets: [DMAMempool.Pointer] = []

	override func process(descriptor: Descriptor) -> Bool {
		switch descriptor.receivePacket() {
		case .notReady:
			return false
		case .unknownError, .multipacket:
			// although there has been an error, in order to keep the queue from blocking
			descriptor.prepareForReceiving()
			return true
		case .packet(let packet):
			// append the packet to our available packets buffer
			availablePackets.append(packet)
			// prepare the descriptor for reuse -> fetch new packet buffer etc
			descriptor.prepareForReceiving()
			return true
		}
	}

	func fetchAvailablePackets() -> [DMAMempool.Pointer] {
		let packets = self.availablePackets
		self.availablePackets = []
		return packets
	}
}

