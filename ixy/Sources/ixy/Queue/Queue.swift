
/// base class for a queue
public struct Queue {
	private let memory: MemoryMap
	internal var packetMempool: DMAMempool
	internal var descriptors: [Descriptor]
	internal var tailIndex: Int = 0
	internal var headIndex: Int = 0
	internal var driver: Driver
	internal let index: UInt

	internal let address: DMAMemory

	public enum QueueError: Error {
		case unknownError
		case memoryError
	}

	init(index: UInt, memory: MemoryMap, packetMempool: DMAMempool, descriptorCount: UInt, driver: Driver) throws {
		self.memory = memory
		self.packetMempool = packetMempool
		self.driver = driver
		self.index = index

		self.address = try DMAMemory(virtual: memory.address)

		let capacity = Int(descriptorCount * 2)
		let queuePointer = memory.address.bindMemory(to: UInt64.self, capacity: capacity)
		queuePointer.update(repeating: UInt64(bitPattern: -1), count: capacity)
		
		let intDescriptorCount = Int(descriptorCount)
		self.descriptors = (0..<intDescriptorCount).map { (Idx) -> Descriptor in
			return Descriptor(queuePointer: queuePointer.advanced(by: Idx * 2), mempool: packetMempool)
		}

	}

	func start() {
		
	}

	static func withHugepageMemory(index: UInt, packetMempool: DMAMempool, descriptorCount: UInt, driver: Driver) throws -> Queue {
		let pageSize = (Int(descriptorCount) * MemoryLayout<Int64>.size * 2)
		let hugepage = try Hugepage(size: pageSize, requireContiguous: true)
		return try Queue(index: index, memory: hugepage.memoryMap, packetMempool: packetMempool, descriptorCount: descriptorCount, driver: driver)
	}
}
