
public class Device {
	public let address: String
	public let receiveQueueCount: UInt
	public let transmitQueueCount: UInt

	internal var receiveQueues: [Queue] = []
	internal var transmitQueues: [Queue] = []

	internal var packetMempool: DMAMempool

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

		let packetCount: UInt = (rxCount + txCount) * Constants.Queue.ringEntryCount
		let packetMemorySize: UInt = packetCount * Constants.Device.maxPacketSize
		print("allocating packet buffer for \(packetCount) packets (size=\(packetMemorySize))")
		guard let packetMemory: UnsafeMutableRawPointer = Hugepage.allocate(size: Int(packetMemorySize), requireContiguous: false)
			else {
				throw DeviceError.memoryError
		}

		guard let packetMempool = DMAMempool(memory: packetMemory, entrySize: Constants.Device.maxPacketSize, entryCount: packetCount) else {
			throw DeviceError.memoryError
		}
		self.packetMempool = packetMempool
	}

	public func open() throws {
		try checkConfig()
	}

	internal func checkConfig() throws {
		// try to open device config
		guard let config = DeviceConfig(address: self.address) else {
			throw DeviceError.ioError
		}

		print("Device Config: \(config)")

		// check vendor
		let vendor = config.vendorID
		guard vendor == Constants.Device.vendorID else {
			print("VendorID \(vendor) not supported.")
			throw DeviceError.wrongDeviceType
		}
	}

	internal func createPacketMemory() {

	}

	internal func createReceiveQueues() {

	}
}

extension Device: DebugDump {
	func dump(_ inset: Int = 0) {
		let pre = createDumpPrefix(inset)
		print("\(pre)Device \(address)")
		print("\(pre)Receive Queues [count=\(receiveQueues.count)")
		receiveQueues.dump(inset + 1)
		print("\(pre)Transmit Queues [count=\(transmitQueues.count)")
		transmitQueues.dump(inset + 1)
	}
}

