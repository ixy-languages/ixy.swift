//
//  Formatting.swift
//  app
//
//  Created by Thomas Günzel on 28.10.2018.
//

import Foundation
import ixy

// MARK: - Print Float with a base unit and magnitude (1.1kB, 1.0MB, etc)
extension Float {
	private static let magnitudes = ["","k","M","G","T"]
	/// convert float to a unit-based string with prefixed magnitudes k,M,G,T. for example: 1 TB
	///
	/// - Parameters:
	///   - baseUnit: the base unit (bit, byte, etc)
	///   - steps: step until next magnitude should be used (1024 for byte, 1000 for packets)
	/// - Returns: the formatted string
	func formatted(baseUnit: String = "", steps: Float = 1000) -> String {
		var nextMagnitudes = Float.magnitudes
		var value = self
		while nextMagnitudes.count > 0 {
			let mag = nextMagnitudes.removeFirst()
			if value <= steps {
				let format = "%4.04f \(mag)\(baseUnit)"
				return String(format: format, value)
			} else {
				value /= steps
			}
		}
		return "\(self) \(baseUnit)"
	}
}

// MARK: - human readable string for the line stats
extension DeviceStats.LineStats {
	/// convert to floats normalized to 1.0s
	///
	/// - Parameter interval: the interval since the last stat update
	/// - Returns: tuple of (packets, bytes)
	func perSecond(interval: Float) -> (Float, Float) {
		return (Float(self.packets) / interval, Float(self.bytes) / interval)
	}

	/// convert to human readable string with bit/s and pkts/s
	///
	/// - Parameter interval: the interval since the last stat update
	/// - Returns: the formatted string
	func formatted(interval: Float) -> String {
		let (packetsPerSecond, bytesPerSecond) = self.perSecond(interval: interval)
		let bitsPerSecond = (bytesPerSecond * 8.0) + (packetsPerSecond * 20 * 8)
		return "\(bitsPerSecond.formatted(baseUnit: "bits/s")), \(packetsPerSecond.formatted(baseUnit: "pkts/s"))"
	}

	/// convert to human readable string with bit and pkts
	///
	/// - Returns: the formatted string
	func formatted() -> String {
		let bitsPerSecond = (Float(self.bytes) * 8.0) + (Float(self.packets) * 20 * 8)
		return "\(bitsPerSecond.formatted(baseUnit: "bits")), \(Float(self.packets).formatted(baseUnit: "pkts"))"
	}
}

// MARK: - Human readable strings for the device stats
extension DeviceStats {
	/// convert to human readable string with bit/s and pkts/s
	///
	/// - Parameter interval: the interval since the last stat update
	/// - Returns: the formatted string
	func formatted(interval: Float) -> String {
		return "TX: \(transmitted.formatted(interval: interval))  RX: \(received.formatted(interval: interval))"
	}

	/// convert to human readable string with bit and pkts
	///
	/// - Returns: the formatted string
	func formatted() -> String {
		return "TX: \(transmitted.formatted())  RX: \(received.formatted())"
	}
}

// MARK: - Hexdump for DMAMempool.Pointer
extension DMAMempool.Pointer {
	/// print hexdump using `print()`
	func dump() {
		guard let bytes = self.packetData else {
			print("No Data!")
			return
		}

		var offset: UInt32 = 0
		var line: String = ""
		for byte in bytes {
			if offset % 16 == 0 {
				if offset > 0 {
					print(line)
					line = ""
				}
				line += String(format: "%04x", arguments: [offset]) + ":"
			}
			if offset % 2 == 0 {
				line += " "
			}
			line += String(format: "%02x", arguments: [byte])

			offset += 1
		}
		print(line)
	}
}

