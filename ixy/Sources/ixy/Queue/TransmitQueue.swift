
public class TransmitQueue: Queue {
	internal var headIndex: Int = 0
	internal var remainingPackets: [DMAMempool.Pointer] = []

	override func start() {
		print("starting transmit queuue \(self.index)")
		driver.start(queue: self)
	}

	override func processBatch() {
		cleanUpOld()
		transmitPackets()
	}

	private func cleanUpOld() {
		while cleanUp(descriptor: descriptors[tailIndex]) {
			headIndex ++< descriptors.count
		}
	}

	private func cleanUp(descriptor: Descriptor) -> Bool {
		guard headIndex != tailIndex else { print("can't clean up further."); return false }
		guard descriptor.transmitted else {
			print("packet was transmitted, cleaning up")
			return false
		}
		descriptor.cleanUpTransmitted()
		return true
	}

	private func transmitPackets() {
		guard remainingPackets.isEmpty == false else { return }
		while transmitNext() {
			tailIndex ++< descriptors.count
		}
		self.driver.update(queue: self, tailIndex: UInt32(tailIndex))
	}

	internal func addPackets(packets: [DMAMempool.Pointer]) {
		self.remainingPackets.append(contentsOf: packets)
	}

	private func transmitNext() -> Bool {
//		guard headIndex != tailIndex else { print("tx queue full \(index)"); return false }
		guard let packet = self.remainingPackets.popLast() else { print("nothing to send"); return false }

		self.descriptors[tailIndex].scheduleForTransmission(packetPointer: packet)
		print("added packet to tail")
		
		return true
	}

	override func process(descriptor: Descriptor) -> Bool {
		return false
	}

}

