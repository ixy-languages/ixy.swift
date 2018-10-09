import Foundation
import ixy

ixy.Log.level = .debug

print("Driver Version: \(Ixy.versionString)")

guard CommandLine.arguments.count > 1 else {
	print("Missing argument!")
	print("Usage: app [pci-address]")
	exit(0)
}

//let pciAddress = CommandLine.arguments[1]
//
//let device = try Device(address: pciAddress)
//
//device.dump()
//
//while true {
//	device.testForward()
//	usleep(1 * 1000 * 1000)
//}


//SomeTests()
