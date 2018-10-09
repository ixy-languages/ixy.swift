import Foundation
import ixy


ixy.Log.level = .debug

print("Driver Version: \(Ixy.versionString)")

guard CommandLine.arguments.count > 2 else {
	print("Missing argument!")
	print("Usage: app [source-pci-address] [sink-pci-address]")
	exit(0)
}

let sourceAddress = CommandLine.arguments[1]
let sinkAddress = CommandLine.arguments[2]

let forward = try Forward(sourceAddress: sourceAddress, sinkAddress: sinkAddress)

forward.loop()
