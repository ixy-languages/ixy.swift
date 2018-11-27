# ixy.swift: Swift Language Features

## Built-in Memory Management

In Swift, memory is automatically managed using ARC (Automatic Reference Counting), which adds retain/release statements at compile-time every time an object enters/leaves the scope or its owning object is destroyed.

However, ixy.swift uses manual memory management for the hugepage tables, where the allocation is done using file descriptors and `mmap`.

Unfortunately, the performance analysis shows, that the retain and release introduce a big performance hit, with little information on why exactly so many calls are necessary.

## Protocols

Protocols enable abstraction where the final object isn't known at compile time.
For example, the subcommand lookup in ixy.swift is done using the following protocol:

	protocol Subcommand {
		init(arguments: [String]) throws
		func loop()
		static var usage: String { get }
	}

This enables the app to switch between subcommands at startup:

	var subcommandType: Subcommand.Type?
	switch subcommandString { // subcommandString = arguments[1]
	case "fwd", "forward":
		subcommandType = Forward.self
	case "simple":
		subcommandType = Simple.self
	[...]
	}
	[...]
	// Execute subcommand
	do {
		let subcommand = try subcommandType.init(arguments: args)
		subcommand.loop()
	} catch _ {
		[...]
	}

## Structs

Structs behave similar to classes in Swift, although they are different in regard to mutability and memory management.

The PCI address is represented as a struct in ixy.swift, which enables easier parsing and therefore – unlike the C version – doesn't require the `0000` prefix.

	public struct PCIAddress {
		let domain: UInt16
		let bus: UInt8
		let device: UInt8
		let function: UInt8
		
		public init(from: String) throws { [...] }
	}

## Classes

By using classes the responsibilities can be split into multiple files and are therefore easier to read and maintain.

The Swift version splits the transmit and receive code into multiple files:

* `Queue`: Base class for queue management
* `ReceiveQueue`: Receive queue logic
* `TransmitQueue`: Transmit queue logic


## Extensions

One of the most commonly used features in ixy.swift are extensions. By introducing extensions, a single type can be extended using multiple files.

A simple example is the `Descriptor` class in ixy.swift, which has two extensions:

* `Descriptor+Receive`: Fill with free pointer, check if packet is ready
* `Descriptor+Transmit`: Fill with packet pointer, check if transmitted

It is also possible to extend types from a library in another target. The `app`, for example, extends the `ixy` library's `DeviceStats` struct with a few methods to print the stats to the command line.

	extension DeviceStats {
		func formatted() -> String {
			return "TX: \(transmitted.formatted())  RX: \(received.formatted())"
		}
	}

## Computed Properties

In addition to stored properties it is possible to add computed properties to types, which provide shorthands to get and (optionally) set values.

The `Driver+Initialization` extension introduces a computed property for the `promiscuousMode`.

	var promiscuousMode: Bool {
		get { return (self[IXGBE_FCTRL] & (IXGBE_FCTRL_MPE | IXGBE_FCTRL_UPE)) > 0 }
		set {
			if newValue { self[IXGBE_FCTRL] |= IXGBE_FCTRL_MPE | IXGBE_FCTRL_UPE }
			else { self[IXGBE_FCTRL] &= ~(IXGBE_FCTRL_MPE | IXGBE_FCTRL_UPE) }
		}
	}

Instead of writing methods like `setPromiscuousMode(_ mode: Bool)`, the dot-notation can be used to access the value.

	// without computed property
	driver.setPromiscuousMode(true)
	// with computed property
	driver.promiscuousMode = true

## Subscripts

Subscripts can be used to access a type like an array or a dictionary. This is extensively used in the `Driver` class.

In the C version, the following code is used to set a control register:

	set_reg32(dev->addr, IXGBE_CTRL, IXGBE_CTRL_RST_MASK);

The Swift version uses subscripts as a shorthand for setting and getting the control registers:

	self[IXGBE_CTRL] = IXGBE_CTRL_RST_MASK

This is done by defining a custom subscript on the `Driver` class:

	subscript(address: UInt32) -> UInt32 {
		get {
			return resource.load(fromByteOffset: Int(address), as: UInt32.self)
		}
		set {
			resource.storeBytes(of: newValue, toByteOffset: Int(address), as: UInt32.self)
		}
	}

## Enums

Although enums are also available in C, they don't have many features.
Swift's enums are more similar to structs and classes, with features like methods, computed properties, and extensions.

The link speed, which is represented by an integer in C, is an enum in the Swift version.

	internal enum LinkSpeed {
		case mbit100
		case gbit1
		case gbit10
	}

By extending the `LinkSpeed` enum, it is possible to fetch the correct link speed using the value in the registers.

	extension LinkSpeed {
		init?(_ value: UInt32) {
			guard (value & IXGBE_LINKS_UP) != 0 else { return nil }
			switch (value & IXGBE_LINKS_SPEED_82599) {
			case IXGBE_LINKS_SPEED_100_82599:
				self = .mbit100
			[...]
			default: return nil
		}
	}