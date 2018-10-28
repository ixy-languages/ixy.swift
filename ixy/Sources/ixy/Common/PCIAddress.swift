//
//  PCIAddress.swift
//  app
//
//  Created by Thomas Günzel on 28.10.2018.
//

import Foundation

// taken from /usr/include/linux/pci.h
// and https://wiki.xen.org/wiki/Bus:Device.Function_(BDF)_Notation

public struct PCIAddress {
	let domain: UInt16
	let bus: UInt8
	let device: UInt8
	let function: UInt8

	public enum ParseError: Error {
		case invalidComponentCount
		case invalidComponent
	}

	public init(domain: UInt16, bus: UInt8, device: UInt8, function: UInt8) {
		self.domain = domain
		self.bus = bus
		self.device = device
		self.function = function
	}
}

extension PCIAddress {
	public init(from: String) throws {
		var components = from.components(separatedBy: ":")
		guard components.count >= 2, components.count <= 3 else { throw ParseError.invalidComponentCount }
		var domain: UInt16 = 0
		var bus: UInt8 = 0
		var device: UInt8 = 0
		var function: UInt8 = 0

		// parse domain
		if components.count == 3 {
			guard let d = UInt16(components.removeFirst(), radix: 16) else { throw ParseError.invalidComponent }
			domain = d
		}

		// parse bus
		guard let b = UInt8(components.removeFirst(), radix: 16) else { throw ParseError.invalidComponent }
		bus = b

		// parse device/function
		let slot = components.removeFirst().components(separatedBy: ".")
		guard slot.count == 2 else { throw ParseError.invalidComponentCount }

		guard let d = UInt8(slot[0], radix: 16),
			let f = UInt8(slot[1], radix: 16) else { throw ParseError.invalidComponent }
		device = d
		function = f

		self.init(domain: domain, bus: bus, device: device, function: function)
	}

	internal var path: String {
		return Constants.pcieBasePath + self.description
	}
}

extension PCIAddress: CustomStringConvertible {
	public var description: String {
		return String(format: "%04x:%02x:%02x.%01x", arguments: [domain, bus, device, function])
	}
}

extension PCIAddress: Equatable {}

public func ==(lhs: PCIAddress, rhs: PCIAddress) -> Bool {
	return (lhs.domain == rhs.domain && lhs.bus == rhs.bus && lhs.device == rhs.device && lhs.function == rhs.function)
}
