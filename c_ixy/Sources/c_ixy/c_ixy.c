//
// Created by Thomas Günzel on 09.10.2018.
//

#include "c_ixy.h"
#include <stdio.h>

#include "ixgbe_type.h"

void c_ixy_test() {
	printf("Hello!\n");
}

void c_ixy_tx_setup(void *packet, uint16_t size, void *address) {
	volatile union ixgbe_adv_tx_desc* txd = packet;
	// NIC reads from here
	txd->read.buffer_addr = address;
	// always the same flags: one buffer (EOP), advanced data descriptor, CRC offload, data length
	txd->read.cmd_type_len =
	IXGBE_ADVTXD_DCMD_EOP | IXGBE_ADVTXD_DCMD_RS | IXGBE_ADVTXD_DCMD_IFCS | IXGBE_ADVTXD_DCMD_DEXT | IXGBE_ADVTXD_DTYP_DATA | size;
	// no fancy offloading stuff - only the total payload length
	// implement offloading flags here:
	// 	* ip checksum offloading is trivial: just set the offset
	// 	* tcp/udp checksum offloading is more annoying, you have to precalculate the pseudo-header checksum
	txd->read.olinfo_status = size << IXGBE_ADVTXD_PAYLEN_SHIFT;
}
