
public class Queue {
	private let memory: DMAMemory
	private let packageMempool: DMAMempool
	private let descriptors: [Descriptor]

	init(memory: DMAMemory, packageMempool: DMAMempool, descriptorCount: Int) {
		self.memory = memory
		self.packageMempool = packageMempool
		let queuePointer = memory.virtual.bindMemory(to: Int64.self, capacity: (descriptorCount * 2))
		self.descriptors = (0..<descriptorCount).map { (Idx) -> Descriptor in
			return Descriptor(queuePointer: queuePointer.advanced(by: Idx * 2), mempool: packageMempool)
		}
	}
}

extension Queue: DebugDump {
	func dump(_ inset: Int = 0) {
		let pre = createDumpPrefix(inset)
		print("\(pre)Queue, memory=\(memory)")
		descriptors.dump(inset + 1, elementName: "Descriptor")
	}
}

