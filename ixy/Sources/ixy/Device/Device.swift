
/// the base class for the Intel 82599
public struct Device {
	public let address: PCIAddress
	public let receiveQueueCount: UInt
	public let transmitQueueCount: UInt

	public internal(set) var receiveQueues: [ReceiveQueue] = []
	public internal(set) var transmitQueues: [TransmitQueue] = []

	internal var packetMempool: DMAMempool
	internal var packetMemoryMap: MemoryMap

	internal var driver: Driver

	internal enum DeviceError: Error {
		case unknownError
		case ioError
		case wrongDeviceType
		case memoryError
	}

	public init(address: PCIAddress, receiveQueues rxCount: UInt = 1, transmitQueues txCount: UInt = 1) throws {
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
		(self.packetMempool, self.packetMemoryMap) = try Device.createPacketBuffer(count: (rxCount + txCount) * 2)

		try open()
	}

	static func createPacketBuffer(count: UInt) throws -> (DMAMempool, MemoryMap) {
		// calculate sizes
		let packetCount: UInt = count * Constants.Queue.ringEntryCount
		let packetMemorySize: UInt = packetCount * Constants.Device.maxPacketSize

		Log.info("Allocating packet buffer for \(packetCount) packets (size=\(packetMemorySize))", component: .device)

		// get hugepage
		let packetHugepage = try Hugepage(size: Int(packetMemorySize), requireContiguous: false)
		let packetMemory: UnsafeMutableRawPointer = packetHugepage.address

		// get physical address
		let packetMempool = try DMAMempool(memory: packetMemory, entrySize: Constants.Device.maxPacketSize, entryCount: packetCount)
		return (packetMempool, packetHugepage.memoryMap)
	}

	public mutating func open() throws {
		// perform various steps to open and initialize the device (method names should be self-explanatory)
		try createReceiveQueues()
		try createTransmitQueues()

		self.driver.resetAndInit()
		let _ = self.driver.readStats() // this resets the device stats

		self.driver.initReceive(queues: self.receiveQueues)
		self.driver.initTransmit(queues: self.transmitQueues)
		for var receiveQueue in self.receiveQueues{
			receiveQueue.start()
		}
		for var transmitQueue in self.transmitQueues{ 
			transmitQueue.start()
		}
		self.driver.promiscuousMode = true

		try self.driver.waitForLink()

		Log.info("Device Ready", component: .device)
	}

	private static func checkConfig(address: PCIAddress) throws {
		// try to open device config
		let config = try DeviceConfig(address: address)

		Log.debug("Device Config: \(config)", component: .device)

		// check vendor
		let vendor = config.vendorID
		guard vendor == Constants.Device.vendorID else {
			Log.error("Vendor \(vendor) not supported", component: .device)
			throw DeviceError.wrongDeviceType
		}
	}

	internal var stats: DeviceStats = DeviceStats(transmittedPackets: 0, transmittedBytes: 0, receivedPackets: 0, receivedBytes: 0)
	public mutating func fetchStats() -> DeviceStats {
		let newStats = self.driver.readStats()
		self.stats += newStats
		return self.stats
	}

	public func readAndResetStats() -> DeviceStats {
		return self.driver.readStats()
	}

	internal mutating func createReceiveQueues() throws {
		let driver = self.driver
		self.receiveQueues = try (0..<self.receiveQueueCount).map { (Idx) -> ReceiveQueue in
			return try ReceiveQueue.withHugepageMemory(index: Idx, packetMempool: self.packetMempool, descriptorCount: Constants.Queue.ringEntryCount, driver: driver)
		}
	}

	internal mutating func createTransmitQueues() throws {
		let driver = self.driver
		self.transmitQueues = try (0..<self.transmitQueueCount).map { (Idx) -> TransmitQueue in
			return try TransmitQueue.withHugepageMemory(index: Idx, packetMempool: self.packetMempool, descriptorCount: Constants.Queue.ringEntryCount, driver: driver)
		}
	}
}

