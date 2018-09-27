# ixy.swift

ixy.cs is a Swift rewrite of the [ixy](https://github.com/emmericp/ixy) userspace network driver.
It supports Intel 82599 10GbE NICs (`ixgbe` family).

**This project is still under heavy development and the readme might not be up to date!**

## Features

* To-Do

## Build instructions

Currently, only Swift 4.1.3 has been tested.
Installation on debian-stretch can be done using the setup script:

	./setup/setup-swift-debian-stretch.sh

It is also necessary to setup hugepages:

    sudo ./setup/setup-hugetlbfs.sh

This project uses the [Swift Package Manager](https://swift.org/package-manager/). It is divided into the ixy library and the app executable.

To build and run the app:

	cd app
	swift run

This will automatically build all the necessary components, including the ixy library.

## Usage

TODO. At the moment, the app doesn't do anything.

## Internals

TODO.

## License

ixy.swift is licensed under the MIT license.

## Disclaimer

**ixy.swift is not production-ready. Do not use it in critical environments or on any systems with data you don't want to lose!**

## Other languages

Check out the [other ixy implementations](https://github.com/ixy-languages).