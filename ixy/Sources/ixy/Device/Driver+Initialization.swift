//
//  Driver+Initialization.swift
//  app
//
//  Created by Thomas Günzel on 29.09.2018.
//

import Foundation

extension Driver {
	static func mmapResource(address: String) throws -> (UnsafeMutableRawPointer, Int, File) {
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

		print("[driver] mmaped resource0: \(path)")

		return (pointer, size, file)
	}

	static func removeDriver(address: String) throws {
		let path = Constants.pcieBasePath + address + "/driver/unbind"
		guard let file = try? File(path: path, flags: O_WRONLY) else {
			print("[driver] could not unlink \(path)")
//			throw Error.unbindError
			return
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

		print("[driver] dma state \(file[4] as UInt16)")
		file[4] |= (1 << 2) as UInt16;
		print("[driver] dma state \(file[4] as UInt16)")
		print("[driver] enabled dma")
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

	func initReceive(queues: [ReceiveQueue]) {
		self[IXGBE_RXCTRL] &= ~IXGBE_RXCTRL_RXEN

		let bufferSizes: [UInt32] = [IXGBE_RXPBSIZE_128KB] + Array<UInt32>(repeating: 0, count: 7)
		for (idx, size) in bufferSizes.enumerated() {
			self[IXGBE_RXPBSIZE(UInt32(idx))] = size
		}

		self[IXGBE_HLREG0] |= IXGBE_HLREG0_RXCRCSTRP
		self[IXGBE_RDRXCTL] |= IXGBE_RDRXCTL_CRCSTRIP

		self[IXGBE_FCTRL] |= IXGBE_FCTRL_BAM

		for (idx, queue) in queues.enumerated() {
			self.initReceive(for: queue, atIndex: idx)
		}

		self[IXGBE_CTRL_EXT] |= IXGBE_CTRL_EXT_NS_DIS

		for i in (0 as UInt32)..<UInt32(queues.count) {
			self[IXGBE_DCA_RXCTRL(i)] &= ~(1 << 12)
		}

		self[IXGBE_RXCTRL] |= IXGBE_RXCTRL_RXEN
	}

	func initReceive(for queue: ReceiveQueue, atIndex index: Int) {
		print("[driver] initalizing receive queue \(index)")
		// enable advanced rx descriptors, we could also get away with legacy descriptors, but they aren't really easier
		let i = UInt32(index)
		self[IXGBE_SRRCTL(i)] = (self[IXGBE_SRRCTL(i)] & ~IXGBE_SRRCTL_DESCTYPE_MASK) | IXGBE_SRRCTL_DESCTYPE_ADV_ONEBUF

		// drop_en causes the nic to drop packets if no rx descriptors are available instead of buffering them
		// a single overflowing queue can fill up the whole buffer and impact operations if not setting this flag
		self[IXGBE_SRRCTL(i)] |= IXGBE_SRRCTL_DROP_EN

//		// setup descriptor ring, see section 7.1.9
		let address: UInt64 = UInt64(Int(bitPattern: queue.address.physical))
		self[IXGBE_RDBAL(i)] = UInt32(address & (0xFFFFFFFF as UInt64))
		self[IXGBE_RDBAH(i)] = UInt32(address >> 32)
		self[IXGBE_RDLEN(i)] = UInt32(Constants.Queue.ringSizeBytes)

//		debug("rx ring %d phy addr:  0x%012lX", i, mem.phy);
//		debug("rx ring %d virt addr: 0x%012lX", i, (uintptr_t) mem.virt);
		self[IXGBE_RDH(i)] = 0
		self[IXGBE_RDT(i)] = 0
	}

	func initTransmit(queues: [TransmitQueue]) {
		self[IXGBE_HLREG0] |= IXGBE_HLREG0_TXCRCEN | IXGBE_HLREG0_TXPADEN


		let bufferSizes: [UInt32] = [IXGBE_TXPBSIZE_40KB] + Array<UInt32>(repeating: 0, count: 7)
		for (idx, size) in bufferSizes.enumerated() {
			self[IXGBE_TXPBSIZE(UInt32(idx))] = size
		}

		self[IXGBE_DTXMXSZRQ] = 0xFFFF as UInt32
		self[IXGBE_RTTDCS] &= ~IXGBE_RTTDCS_ARBDIS

		for (idx, queue) in queues.enumerated() {
			self.initTransmit(for: queue, atIndex: idx)
		}

		self[IXGBE_DMATXCTL] = IXGBE_DMATXCTL_TE
	}

	func initTransmit(for queue: TransmitQueue, atIndex index: Int) {
		print("[driver] initalizing transmit queue \(index)")
		let i = UInt32(index)

		let address: UInt64 = UInt64(Int(bitPattern: queue.address.physical))
		self[IXGBE_TDBAL(i)] = UInt32(address & (0xFFFFFFFF as UInt64))
		self[IXGBE_TDBAH(i)] = UInt32(address >> 32)
		self[IXGBE_TDLEN(i)] = UInt32(Constants.Queue.ringSizeBytes)

		var txdctl = self[IXGBE_TXDCTL(i)]
		txdctl &= ~(0x3F | (0x3F << 8) | (0x3f << 16))
		txdctl |= (36 | (8 << 8) | (4 << 16))
		self[IXGBE_TXDCTL(i)] = txdctl
	}

	func waitForLink() {
		print("[driver] waiting for link...")
		var remaining: UInt32 = 30 * 1000000
		let interval: UInt32 = 10 * 1000
		var speed: LinkSpeed? = self.linkSpeed

		while speed == nil && remaining > 0 {
			usleep(interval)
			remaining -= interval
			speed = self.linkSpeed
		}

		print("[driver] speed: \(speed?.description ?? "unavailable")")

		if speed == nil {
			exit(1)
		}
	}

	var linkSpeed: LinkSpeed? {
		return LinkSpeed(self[IXGBE_LINKS])
	}

	var promiscuousMode: Bool {
		get {
			return (self[IXGBE_FCTRL] & (IXGBE_FCTRL_MPE | IXGBE_FCTRL_UPE)) > 0
		}
		set {
			if newValue {
				self[IXGBE_FCTRL] |= IXGBE_FCTRL_MPE | IXGBE_FCTRL_UPE
			} else {
				self[IXGBE_FCTRL] &= ~(IXGBE_FCTRL_MPE | IXGBE_FCTRL_UPE)
			}
		}
	}
}
