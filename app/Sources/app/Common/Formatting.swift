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
	static let magnitudes = ["","k","M","G","T"]
	func formatted(baseUnit: String = "", steps: Float = 1024) -> String {
		var nextMagnitudes = Float.magnitudes
		var value = self
		while nextMagnitudes.count > 0 {
			let mag = nextMagnitudes.removeFirst()
			if value <= steps {
				let format = "%4.01f \(mag)\(baseUnit)"
				return String(format: format, value)
			} else {
				value /= steps
			}
		}
		return "\(self) \(baseUnit)"
	}
}

extension DeviceStats.LineStats {
	func perSecond(interval: Float) -> (Float, Float) {
		return (Float(self.packets) / interval, Float(self.bytes) / interval)
	}

	func formatted(interval: Float) -> String {
		let (packetsPerSecond, bytesPerSecond) = self.perSecond(interval: interval)
		let bitsPerSecond = (bytesPerSecond * 8.0) + (packetsPerSecond * 20 * 8)
		return "\(bitsPerSecond.formatted(baseUnit: "bits/s")), \(packetsPerSecond.formatted(baseUnit: "pkgs/s", steps: 1000.0))"
	}

	func formatted() -> String {
		let bitsPerSecond = (Float(self.bytes) * 8.0) + (Float(self.packets) * 20 * 8)
		return "\(bitsPerSecond.formatted(baseUnit: "bits")), \(Float(self.packets).formatted(baseUnit: "pkgs", steps: 1000.0))"
	}
}

extension DeviceStats {
	func formatted(interval: Float) -> String {
		return "TX: \(transmitted.formatted(interval: interval))  RX: \(received.formatted(interval: interval))"
	}

	func formatted() -> String {
		return "TX: \(transmitted.formatted())  RX: \(received.formatted())"
	}
}

// MARK: - Hexdump for DMAMempool.Pointer
extension DMAMempool.Pointer {
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

