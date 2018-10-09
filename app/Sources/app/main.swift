import Foundation
import ixy

ixy.Log.level = .info

print("Driver Version: \(Ixy.versionString)")

let args = CommandLine.arguments.dropFirst()

if args.first == "simple" {
	guard args.count > 1 else {
		print("Missing argument!")
		print("Usage: app simple [pci-address]")
		exit(0)
	}
	let address = args[2]
	Log.log("running 'simple' for \(address)", level: .info, component: "app")
	do {
		let simple = try Simple(address: address)
		simple.loop()
	} catch {
		print("error: \(error)")
	}
} else if args.first == "fwd" {
	guard args.count > 2 else {
		print("Missing argument!")
		print("Usage: app fwd [source-pci-address] [sink-pci-address]")
		exit(0)
	}
	let sourceAddress = args[2]
	let sinkAddress = args[3]

	do {
		let forward = try Forward(sourceAddress: sourceAddress, sinkAddress: sinkAddress)
		forward.loop()
	} catch {
		print("error: \(error)")
	}
} else {
	print("Missing argument!")
	print("Usage: app [fwd|simple]")
}




