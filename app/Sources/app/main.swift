import Foundation
import ixy

print("Driver Version: \(Ixy.versionString)")

guard CommandLine.arguments.count > 1 else {
	print("Missing argument!")
	print("Usage: app [pci-address]")
	exit(0)
}

let pciAddress = CommandLine.arguments[1]

let device = Device(address: pciAddress)
try device.open()
