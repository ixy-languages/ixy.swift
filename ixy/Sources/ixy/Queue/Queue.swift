
public class Queue {
	private let memory: MemoryMap
	private let packageMempool: DMAMempool
	private let descriptors: [Descriptor]
	private var tailIndex: Int = 0

	required init(memory: MemoryMap, packageMempool: DMAMempool, descriptorCount: UInt) {
		self.memory = memory
		self.packageMempool = packageMempool
		let queuePointer = memory.address.bindMemory(to: Int64.self, capacity: Int(descriptorCount * 2))
		let intDescriptorCount = Int(descriptorCount)
		self.descriptors = (0..<intDescriptorCount).map { (Idx) -> Descriptor in
			return Descriptor(queuePointer: queuePointer.advanced(by: Idx * 2), mempool: packageMempool)
		}
	}

	final func processBatch() {
		while process(descriptor: descriptors[tailIndex]) {
			tailIndex ++< descriptors.count
		}
	}

	func process(descriptor: Descriptor) -> Bool {
		return false
	}

	static func withHugepageMemory(packageMempool: DMAMempool, descriptorCount: UInt) throws -> Self {
		let pageSize = (Int(descriptorCount) * MemoryLayout<Int64>.size * 2)
		let hugepage = try Hugepage(size: pageSize, requireContiguous: true)
		return self.init(memory: hugepage.memoryMap, packageMempool: packageMempool, descriptorCount: descriptorCount)
	}
}

extension Queue: DebugDump {
	public func dump(_ inset: Int = 0) {
		let pre = createDumpPrefix(inset)
		print("\(pre)Queue, memory=\(memory), count=\(descriptors.count)")
//		descriptors.dump(inset + 1, elementName: "Descriptor")
	}
}

