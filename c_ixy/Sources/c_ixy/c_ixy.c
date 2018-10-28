//
// Created by Thomas Günzel on 09.10.2018.
//

#include "c_ixy.h"
#include <stdio.h>
#include <string.h>

#include "ixgbe_type.h"

void c_ixy_test() {
	printf("Hello!\n");
}

void c_ixy_tx_setup(void *packet, uint16_t size, void *address) {
	volatile union ixgbe_adv_tx_desc* txd = packet;
	// NIC reads from here
	txd->read.buffer_addr = (uintptr_t)address;
	// always the same flags: one buffer (EOP), advanced data descriptor, CRC offload, data length
	txd->read.cmd_type_len =
	IXGBE_ADVTXD_DCMD_EOP | IXGBE_ADVTXD_DCMD_RS | IXGBE_ADVTXD_DCMD_IFCS | IXGBE_ADVTXD_DCMD_DEXT | IXGBE_ADVTXD_DTYP_DATA | size;
	// no fancy offloading stuff - only the total payload length
	// implement offloading flags here:
	// 	* ip checksum offloading is trivial: just set the offset
	// 	* tcp/udp checksum offloading is more annoying, you have to precalculate the pseudo-header checksum
	txd->read.olinfo_status = size << IXGBE_ADVTXD_PAYLEN_SHIFT;
}

bool c_ixy_tx_desc_done(void *desc) {
	volatile union ixgbe_adv_tx_desc* txd = desc;
	uint32_t status = txd->wb.status;
	// hardware sets this flag as soon as it's sent out, we can give back all bufs in the batch back to the mempool
	if (status & IXGBE_ADVTXD_STAT_DD) {
		return true;
	}
	return false;
}

uint64_t c_ixy_u64_from_pointer(void *pointer) {
	return (uint64_t)pointer;
}

uint16_t c_ixy_u16_from_u32(uint32_t u32) {
	return (uint16_t)u32;
}

static inline uint32_t get_reg32(const uint8_t* addr, int reg) {
	return *((volatile uint32_t*) (addr + reg));
}

int c_ixy_rx_desc_ready(void *desc) {
	volatile union ixgbe_adv_rx_desc* desc_ptr = desc;
	uint32_t status = desc_ptr->wb.upper.status_error;
	if (status & IXGBE_RXDADV_STAT_DD) {
		if (!(status & IXGBE_RXDADV_STAT_EOP)) {
			return -1;
		}
		return 1;
	}
	return 0;
}

uint32_t c_ixy_rx_desc_size(void *desc_ptr) {
	union ixgbe_adv_rx_desc *desc = desc_ptr;
	return desc->wb.upper.length;
}


// TODO: Delete!

// excluding CRC (offloaded by default)
#define PKT_SIZE 60

static const uint8_t pkt_data[] = {
	0x01, 0x02, 0x03, 0x04, 0x05, 0x06, // dst MAC
	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, // src MAC
	0x08, 0x00,                         // ether type: IPv4
	0x45, 0x00,                         // Version, IHL, TOS
	(PKT_SIZE - 14) >> 8,               // ip len excluding ethernet, high byte
	(PKT_SIZE - 14) & 0xFF,             // ip len exlucding ethernet, low byte
	0x00, 0x00, 0x00, 0x00,             // id, flags, fragmentation
	0x40, 0x11, 0x00, 0x00,             // TTL (64), protocol (UDP), checksum
	0x0A, 0x00, 0x00, 0x01,             // src ip (10.0.0.1)
	0x0A, 0x00, 0x00, 0x02,             // dst ip (10.0.0.2)
	0x00, 0x2A, 0x05, 0x39,             // src and dst ports (42 -> 1337)
	(PKT_SIZE - 20 - 14) >> 8,          // udp len excluding ip & ethernet, high byte
	(PKT_SIZE - 20 - 14) & 0xFF,        // udp len exlucding ip & ethernet, low byte
	0x00, 0x00,                         // udp checksum, optional
	'i', 'x', 'y'                       // payload
	// rest of the payload is zero-filled because mempools guarantee empty bufs
};

// calculate a IP/TCP/UDP checksum
static uint16_t calc_ip_checksum(uint8_t* data, uint32_t len) {
	if (len % 1) { return 0; }
	uint32_t cs = 0;
	for (uint32_t i = 0; i < len / 2; i++) {
		cs += ((uint16_t*)data)[i];
		if (cs > 0xFFFF) {
			cs = (cs & 0xFFFF) + 1; // 16 bit one's complement
		}
	}
	return ~((uint16_t) cs);
}


uint16_t c_ixy_dbg_packet_size() {
	return PKT_SIZE;
}
void c_ixy_dbg_fill_packet(void *packet) {
	memcpy(packet, pkt_data, sizeof(pkt_data));
	*(uint16_t*) (packet + 24) = calc_ip_checksum(packet + 14, 20);
}
