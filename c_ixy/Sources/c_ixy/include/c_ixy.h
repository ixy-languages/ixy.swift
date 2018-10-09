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

#endif //IXY_C_IXY_H
