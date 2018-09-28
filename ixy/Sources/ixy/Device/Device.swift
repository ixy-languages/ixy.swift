
public class Device {
	public let address: String
	public let receiveQueueCount: UInt
	public let transmitQueueCount: UInt

	internal var receiveQueues: [ReceiveQueue] = []
	internal var transmitQueues: [Queue] = []

	internal var packetMempool: DMAMempool
	internal var packetMemoryMap: MemoryMap

	internal var driver: Driver

	internal enum DeviceError: Error {
		case unknownError
		case ioError
		case wrongDeviceType
		case memoryError
	}

	public init(address: String, receiveQueues rxCount: UInt = 1, transmitQueues txCount: UInt = 1) throws {
		// set properties
		self.address = address
		self.receiveQueueCount = rxCount
		self.transmitQueueCount = txCount

		// unfortunately this has to be a static method, as we would have to allocate
		// the mempool before checking the device if it would be a normal method
		try Device.checkConfig(address: address)

		// initialize the driver
		self.driver = try Driver(address: address)

		// create packet buffer and assign
		(self.packetMempool, self.packetMemoryMap) = try Device.createPacketBuffer(count: rxCount + txCount)

		try open()
	}

	static func createPacketBuffer(count: UInt) throws -> (DMAMempool, MemoryMap) {
		// calculate sizes
		let packetCount: UInt = count * Constants.Queue.ringEntryCount
		let packetMemorySize: UInt = packetCount * Constants.Device.maxPacketSize

		print("allocating packet buffer for \(packetCount) packets (size=\(packetMemorySize))")

		// get hugepage
		let packetHugepage = try Hugepage(size: Int(packetMemorySize), requireContiguous: false)
		let packetMemory: UnsafeMutableRawPointer = packetHugepage.address

		// get physical address
		guard let packetMempool = DMAMempool(memory: packetMemory, entrySize: Constants.Device.maxPacketSize, entryCount: packetCount) else {
			throw DeviceError.memoryError
		}

		return (packetMempool, packetHugepage.memoryMap)
	}

	public func open() throws {
		try createReceiveQueues()
		try createTransmitQueues()
	}

	private static func checkConfig(address: String) throws {
		// try to open device config
		let config = try DeviceConfig(address: address)

		print("Device Config: \(config)")

		// check vendor
		let vendor = config.vendorID
		guard vendor == Constants.Device.vendorID else {
			print("VendorID \(vendor) not supported.")
			throw DeviceError.wrongDeviceType
		}
	}

	internal func createReceiveQueues() throws {
		self.receiveQueues = try (0..<self.receiveQueueCount).map { (Idx) -> ReceiveQueue in
			return try ReceiveQueue.withHugepageMemory(packageMempool: self.packetMempool, descriptorCount: Constants.Queue.ringEntryCount)
		}
	}

	internal func createTransmitQueues() throws {

	}
}

extension Device: DebugDump {
	public func dump(_ inset: Int = 0) {
		let pre = createDumpPrefix(inset)
		print("\(pre)Device \(address)")
		print("\(pre)Receive Queues [count=\(receiveQueues.count)]")
		receiveQueues.dump(inset + 1)
		print("\(pre)Transmit Queues [count=\(transmitQueues.count)]")
		transmitQueues.dump(inset + 1)
	}
}

