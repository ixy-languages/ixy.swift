import Foundation

public struct Ixy {
	public static let majorVersion: UInt = 0
	public static let minorVersion: UInt = 1

	public static let versionString: String = "0.1"
}



func pointerTest() {
	guard let f = File(path: "/Users/thomasguenzel/Documents/Uni/WS1819/NetworkDriver/Code/bin.data", flags: O_RDWR)
		else { fatalError("file not open"); }

	let size = 16
	guard let pointer: UnsafeMutableRawPointer = mmap(nil, size, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FILE, f.fd, 0) else { fatalError("mmap failed") }
	guard pointer != MAP_FAILED else { fatalError("mmap failed: errno \(errno)") }

	let someNumber: UInt8 = 24
	let aNum: UInt8 = pointer.load(fromByteOffset: 0, as: UInt8.self)
	pointer.storeBytes(of: someNumber, toByteOffset: 0, as: UInt8.self)
	let bNum: UInt8 = pointer.load(fromByteOffset: 0, as: UInt8.self)
	print("num: \(aNum) \(bNum)")

	munmap(pointer, size)
}

public func SomeTests() {
//	pointerTest()
//	guard let f = File(path: "/Users/thomasguenzel/Documents/Uni/WS1819/NetworkDriver/Code/bin.data", flags: O_RDONLY)
//		else { fatalError("file not open"); }
//
//	var x: Int8 = 0
//	var y: Int16 = 0
//	var z: Int32 = 0
//	do {
//		try f.read(&x, offset: 0)
//		print("Got X");
//		try f.read(&y, offset: 2)
//		print("Got Y");
//		try f.read(&z, offset: 4)
//		print("Got Z");
//	} catch {
//		print("Error: \(error)")
//	}
//
//	print("X: \(x)")
//	print("Y: \(y)")
//	print("Z: \(z)")
//
//	let a: Int8 = 12

//	let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 32, alignment: 1)

//	let inc = Atomic<UInt16>(value: 0)
//
//	while inc.value < 200 {
//		inc.increment(by: 4)
//		print("Value: \(inc.value)")
//	}
//
//	print("Value: \(inc.value)")

//	buffer.
}

