
public struct ReceiveQueue {
	var queue : Queue
	private var availablePackets: [DMAMempool.Pointer] = []

	public var receivedPackets: Int = 0

	init(index: UInt, memory: MemoryMap, packetMempool: DMAMempool, descriptorCount: UInt, driver: Driver) throws {
		try self.queue = Queue(index: index, memory: memory, packetMempool: packetMempool, descriptorCount: descriptorCount, driver: driver)
	}
	
	/// fetches available packet from the ring buffer and returns them
	///
	/// - Parameter limit: optionally limit the packet count
	/// - Returns: array of packets
	public mutating func fetchAvailablePackets(limit: Int? = nil) -> [DMAMempool.Pointer] {
		self.availablePackets = []
		if let limit = limit {
			availablePackets.reserveCapacity(limit)
		}
		processBatch(limit: limit)
		let packets = self.availablePackets
		// set to zero to remove strong references
		self.availablePackets = []
		return packets
	}

	mutating func processBatch(limit: Int? = nil) {
		var lastIndex = self.queue.tailIndex
		let lastRxIndex = self.queue.tailIndex
		// split using if else to reduce unnecessary overhead
		if var remaining = limit {
			while remaining > 0, process(index: self.queue.tailIndex) {
				lastIndex = self.queue.tailIndex
				self.queue.tailIndex ++< self.queue.descriptors.count
				remaining -= 1
			}
		} else {
			while process(index: self.queue.tailIndex) {
				lastIndex = self.queue.tailIndex
				self.queue.tailIndex ++< self.queue.descriptors.count
			}
		}

		// update register if necessary
		if lastRxIndex != self.queue.tailIndex {
			self.queue.driver.update(receiveQueue: self, tailIndex: UInt32(lastIndex))
		}
	}

	mutating func process(index: Int) -> Bool {
		switch self.queue.descriptors[index].receivePacket() {
		case .notReady:
			Log.debug("Packet not ready", component: .rx)
			return false
		case .unknownError, .multipacket:
			// although there has been an error, in order to keep the queue from blocking
			receivedPackets += 1
			self.queue.descriptors[index].prepareForReceiving()
			return true
		case .packet(let packet):
			// append the packet to our available packets buffer
			receivedPackets += 1
			availablePackets.append(packet)
			// prepare the descriptor for reuse -> fetch new packet buffer etc
			self.queue.descriptors[index].prepareForReceiving()
			return true
		}
	}

	mutating func process(descriptor: inout Descriptor) -> Bool {
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

	mutating func start() {
		Log.debug("Starting \(self.queue.index)", component: .rx)
		for indx in 0..<self.queue.descriptors.count {
			self.queue.descriptors[indx].prepareForReceiving()
		}
		self.queue.driver.start(receiveQueue: self)
	}

	static func withHugepageMemory(index: UInt, packetMempool: DMAMempool, descriptorCount: UInt, driver: Driver) throws -> ReceiveQueue {
		let pageSize = (Int(descriptorCount) * MemoryLayout<Int64>.size * 2)
		let hugepage = try Hugepage(size: pageSize, requireContiguous: true)
		return try ReceiveQueue(index: index, memory: hugepage.memoryMap, packetMempool: packetMempool, descriptorCount: descriptorCount, driver: driver)
	}
}

