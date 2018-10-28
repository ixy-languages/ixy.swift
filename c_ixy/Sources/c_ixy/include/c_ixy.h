//
// Created by Thomas Günzel on 09.10.2018.
//

#ifndef IXY_C_IXY_H
#define IXY_C_IXY_H

#include <stdint.h>
#include <stdbool.h>

// sets the address for a tx descriptor
void c_ixy_tx_setup(void *packet, uint16_t size, void *address);
// checks whether the tx descriptor is done
bool c_ixy_tx_desc_done(void *desc);

// convert pointer to u64
uint64_t c_ixy_u64_from_pointer(void *pointer);
// convert u32 to u16
uint16_t c_ixy_u16_from_u32(uint32_t u32);

// checks if the rx descriptor is ready
int c_ixy_rx_desc_ready(void *desc);
// checks the rx descriptor's size
uint32_t c_ixy_rx_desc_size(void *desc);

// return debug packet size
uint16_t c_ixy_dbg_packet_size();
// fills debug packet with data
void c_ixy_dbg_fill_packet(void *packet);


#endif //IXY_C_IXY_H
