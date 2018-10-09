
public class Queue {
	private let memory: MemoryMap
	private let packageMempool: DMAMempool
	internal let descriptors: [Descriptor]
	internal var tailIndex: Int = 0
	internal let driver: Driver
	internal let index: UInt

	internal let address: DMAMemory

	public enum QueueError: Error {
		case unknownError
		case memoryError
	}

	required init(index: UInt, memory: MemoryMap, packageMempool: DMAMempool, descriptorCount: UInt, driver: Driver) throws {
		self.memory = memory
		self.packageMempool = packageMempool
		self.driver = driver
		self.index = index

		self.address = try DMAMemory(virtual: memory.address)

		let capacity = Int(descriptorCount * 2)
		let queuePointer = memory.address.bindMemory(to: UInt64.self, capacity: capacity)
		queuePointer.assign(repeating: UInt64(bitPattern: -1), count: capacity)
		
		let intDescriptorCount = Int(descriptorCount)
		self.descriptors = (0..<intDescriptorCount).map { (Idx) -> Descriptor in
			return Descriptor(queuePointer: queuePointer.advanced(by: Idx * 2), mempool: packageMempool)
		}

	}

	func start() {
		
	}

	public func processBatch() {
		while process(descriptor: descriptors[tailIndex]) {
			tailIndex ++< descriptors.count
		}
	}

	func process(descriptor: Descriptor) -> Bool {
		return false
	}

	static func withHugepageMemory(index: UInt, packageMempool: DMAMempool, descriptorCount: UInt, driver: Driver) throws -> Self {
		let pageSize = (Int(descriptorCount) * MemoryLayout<Int64>.size * 2)
		let hugepage = try Hugepage(size: pageSize, requireContiguous: true)
		return try self.init(index: index, memory: hugepage.memoryMap, packageMempool: packageMempool, descriptorCount: descriptorCount, driver: driver)
	}
}

extension Queue: DebugDump {
	public func dump(_ inset: Int = 0) {
		let pre = createDumpPrefix(inset)
		print("\(pre)Queue, memory=\(memory), count=\(descriptors.count)")
//		descriptors.dump(inset + 1, elementName: "Descriptor")
	}
}

