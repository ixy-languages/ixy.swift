# ixy.swift

ixy.swift is a Swift rewrite of the [ixy](https://github.com/emmericp/ixy) userspace network driver.
It supports Intel 82599 10GbE NICs (`ixgbe` family).

## Features

* Driver for Intel 82599 NICs
* 100% Swift
* No dependencies except the standard Swift libraries

## Build instructions

Currently, only Swift 4.2 has been tested.
Installation on debian-stretch can be done using the setup script:

	./setup/setup-swift-debian-stretch.sh
	source setup/setup-swift-paths.sh

It is also necessary to setup hugepages:

    sudo ./setup/setup-hugetlbfs.sh

This project uses the [Swift Package Manager](https://swift.org/package-manager/). It is divided into the ixy library and the app executable.

To build and run the app:

	cd app
	swift build

This will automatically build all the necessary components, including the ixy library.

## Usage

The app project builds an executable with 3 possible commands: forward, simple, and ping.

The binary can be either run using the swift package manager (which builds the project if it's out-of-date) or by directly executing the binary. The following examples all use `swift run app`, but there are multiple ways to execute the app.

Command(s) | Configuration | Description
---- | ---- | ----
`swift run app [...]` | Debug | Builds and runs the app
`./.build/debug/app [...]` | Debug | Runs the app (requires `swift build`)
`swift run -c release app [...]` | Release | Builds and runs the app
`./.build/release/app [...]` | Release | Runs the app (requires `swift build -c release`)

### Forward

	swift run app fwd [device1] [device2]
	swift run app forward [device1] [device2]

Forwards data from `device1` (PCI Address) to `device2` (PCI Address).
For example:

	swift run app forward 0000:01:00.0 0000:03:00.0
	swift run app fwd 01:00.0 03:00.0

### Simple

	swift run simple [device]

Listens to packets on the `device` (PCI Address) and prints their content similar to hexdump. Examples:

	swift run app simple 01:00.0

### Ping

	swift run app ping [device]
	swift run app pktgen [device]

Sends dummy packets on the `device` (PCI Address) and prints how many packets were received.
Examples:

	swift run app ping 03:00.0

## Internals

This project is split into two parts: the app and the ixy library. The app contains the command line argument parsing and basic logic of the commands, while the ixy library handles the abstraction of the NIC.

The code should be sufficiently documented using comments. A good place to start is [Device.swift](ixy/Sources/ixy/Device/Device.swift) in the ixy library project.


## Performance Evaluation

A small performance evaluation with other available ixy versions (C, Rust, Go, C#) can be [found here](performance/README.md).

## License

ixy.swift is licensed under the MIT license.

## Disclaimer

**ixy.swift is not production-ready. Do not use it in critical environments or on any systems with data you don't want to lose!**

## Other languages

Check out the [other ixy implementations](https://github.com/ixy-languages).