//
//  Driver+Initialization.swift
//  app
//
//  Created by Thomas Günzel on 29.09.2018.
//

import Foundation

// todo: create regex that accepts mask compositions
let IXGBE_CTRL_RST_MASK: UInt32 = (IXGBE_CTRL_LNK_RST | IXGBE_CTRL_RST)
let IXGBE_AUTOC_LMS_MASK: UInt32 = (0x7 << IXGBE_AUTOC_LMS_SHIFT)
let IXGBE_AUTOC_LMS_10G_SERIAL: UInt32 = (0x3 << IXGBE_AUTOC_LMS_SHIFT)
let IXGBE_AUTOC_10G_XAUI: UInt32 = (0x0 << IXGBE_AUTOC_10G_PMA_PMD_SHIFT)


extension Driver {
	static func mmapResource(address: String) throws -> (UnsafeMutableRawPointer, Int) {
		let path = Constants.pcieBasePath + address + "/resource0"
		let file = try File(path: path, flags: O_RDWR)

		guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
			let size = attributes[FileAttributeKey.size] as? Int else {
				print("[driver] getting filesize failed \(path)")
				throw Error.ioError
		}

		guard let pointer = mmap(nil, size, PROT_READ | PROT_WRITE, MAP_SHARED, file.fd, 0),
			pointer != MAP_FAILED else {
				print("[driver] mmap failed: \(errno)")
				throw Error.ioError
		}

		return (pointer, size)
	}

	static func removeDriver(address: String) throws {
		let path = Constants.pcieBasePath + address + "/driver/unbind"
		guard let file = try? File(path: path, flags: O_WRONLY) else {
			print("[driver] could not unlink \(path)")
			throw Error.unbindError
		}

		file.writeString(address)
		print("[driver] unbound driver")
	}

	static func enableDMA(address: String) throws {
		let path = Constants.pcieBasePath + address + "/config"
		guard let file = try? File(path: path, flags: O_RDWR) else {
			print("[driver] could not unlink \(path)")
			throw Error.unbindError
		}

		file[4] |= (1 << 2) as UInt16;
	}

	func resetAndInit() {
		reset()
		initDevice()
	}

	func reset() {
		print("[device] resetting \(address)")
		// section 4.6.3.1 - disable all interrupts
		self[IXGBE_EIMC] = 0x7FFFFFFF

		// section 4.6.3.2
		self[IXGBE_CTRL] = IXGBE_CTRL_RST_MASK
		self.wait(until: IXGBE_CTRL, didClearMask: IXGBE_CTRL_RST_MASK)
		usleep(10000)

		// section 4.6.3.1 - disable interrupts again after reset
		self[IXGBE_EIMC] = 0x7FFFFFFF
	}

	func initDevice() {
		print("[device] initializing \(address)")

		self.wait(until: IXGBE_EEC, didSetMask: IXGBE_EEC_ARD)
		self.wait(until: IXGBE_RDRXCTL, didSetMask: IXGBE_RDRXCTL_DMAIDONE)

		initLink()
	}

	func initLink() {
		self[IXGBE_AUTOC] = (self[IXGBE_AUTOC] & ~IXGBE_AUTOC_LMS_MASK) | IXGBE_AUTOC_LMS_10G_SERIAL
		self[IXGBE_AUTOC] = (self[IXGBE_AUTOC] & ~IXGBE_AUTOC_10G_PMA_PMD_MASK) | IXGBE_AUTOC_10G_XAUI

		self[IXGBE_AUTOC] |= IXGBE_AUTOC_AN_RESTART
	}

	var promiscuousMode: Bool {
		get {
			return (self[IXGBE_FCTRL] & (IXGBE_FCTRL_MPE | IXGBE_FCTRL_UPE)) > 0
		}
		set {
			if newValue {
				self[IXGBE_FCTRL] |= IXGBE_FCTRL_MPE | IXGBE_FCTRL_UPE
			} else {
				self[IXGBE_FCTRL] ^= IXGBE_FCTRL_MPE | IXGBE_FCTRL_UPE
			}
		}
	}
}
