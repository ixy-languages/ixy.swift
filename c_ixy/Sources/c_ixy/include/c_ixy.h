//
// Created by Thomas Günzel on 09.10.2018.
//

#ifndef IXY_C_IXY_H
#define IXY_C_IXY_H

#include <stdint.h>
#include <stdbool.h>

void c_ixy_test();
void c_ixy_tx_setup(void *packet, uint16_t size, void *address);
bool c_ixy_tx_desc_done(void *desc);

uint64_t u64_from_pointer(void *pointer);
uint16_t u16_from_u32(uint32_t u32);

uint32_t dbg_desc_err_count(void *pointer);

int c_ixy_rx_desc_ready(void *desc);
uint32_t c_ixy_rx_desc_size(void *desc);

uint16_t dbg_packet_size();
void dbg_fill_packet(void *packet);


#endif //IXY_C_IXY_H
