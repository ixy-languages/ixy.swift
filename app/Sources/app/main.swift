import Foundation
import ixy

ixy.Log.level = .info
ixy.Log.enableColors = false

// drop the first argument (path to executable)
var args = CommandLine.arguments
_ = args.removeFirst()

// get the subcommand string
let subcommandString = args.removeFirst()

// try to match subcommand
var subcommandType: Subcommand.Type?
switch subcommandString {
case "fwd", "forward":
	subcommandType = Forward.self
case "simple":
	subcommandType = Simple.self
case "ping","pktgen":
	subcommandType = PacketGen.self
default:
	break
}

// check if subcommand was known
guard let subcommandType = subcommandType else {
	Log.log("Unknown command \(subcommandString)", level: .error, component: "app")
	Log.log("Usage: app [fwd|simple|ping]", level: .error, component: "app")
	exit(0)
}

// initialize the subcommand, run the loop and print encountered errors
do {
	// CORE
	// here, the subcommand is initialized and looped
	let subcommand = try subcommandType.init(arguments: args)
	subcommand.loop()
} catch SubcommandError.notEnoughArguments {
	Log.log("Not enough arguments!", level: .error, component: "app")
	Log.log("Usage: app \(subcommandString) \(subcommandType.usage)", level: .error, component: "app")
} catch SubcommandError.argumentError(let err) {
	Log.log("Invalid argument: \(err)", level: .error, component: "app")
	Log.log("Usage: app \(subcommandString) \(subcommandType.usage)", level: .error, component: "app")
} catch {
	Log.log("Error: \(error)", level: .error, component: "app")
}
