
public class Device {
	private let address: String

	internal enum DeviceError: Error {
		case unknownError
		case ioError
		case wrongDeviceType
	}

	public init(address: String) {
		self.address = address
	}

	public func open() throws {
		guard let config = DeviceConfig(address: self.address) else {
			throw DeviceError.ioError
		}

		print("Device Config: \(config)")
	}
	
}

