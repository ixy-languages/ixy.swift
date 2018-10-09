//
//  ConvertedDefines+Macros.swift
//  ixy
//
//  Created by Thomas Günzel on 01.10.2018.
//

import Foundation

internal let IXGBE_CTRL_RST_MASK: UInt32 = (IXGBE_CTRL_LNK_RST | IXGBE_CTRL_RST)
internal let IXGBE_AUTOC_LMS_MASK: UInt32 = (0x7 << IXGBE_AUTOC_LMS_SHIFT)
internal let IXGBE_AUTOC_LMS_10G_SERIAL: UInt32 = (0x3 << IXGBE_AUTOC_LMS_SHIFT)
internal let IXGBE_AUTOC_10G_XAUI: UInt32 = (0x0 << IXGBE_AUTOC_10G_PMA_PMD_SHIFT)

internal func IXGBE_RXPBSIZE(_ i: UInt32) -> UInt32 {
	return (0x03C00 + ((i) * 4))
}

internal func IXGBE_SRRCTL(_ i: UInt32) -> UInt32 {
	return (((i) <= 15) ? (0x02100 + ((i) * 4)) :
		(((i) < 64) ? (0x01014 + ((i) * 0x40)) :
			(0x0D014 + (((i) - 64) * 0x40))))
}

internal func IXGBE_RDBAL(_ i: UInt32) -> UInt32 {
	return (((i) < 64) ? (0x01000 + ((i) * 0x40)) : (0x0D000 + (((i) - 64) * 0x40)))
}

internal func IXGBE_RDBAH(_ i: UInt32) -> UInt32 {
	return (((i) < 64) ? (0x01004 + ((i) * 0x40)) : (0x0D004 + (((i) - 64) * 0x40)))
}

internal func IXGBE_RDLEN(_ i: UInt32) -> UInt32 {
	return (((i) < 64) ? (0x01008 + ((i) * 0x40)) : (0x0D008 + (((i) - 64) * 0x40)))
}

internal func IXGBE_RDH(_ i: UInt32) -> UInt32 {
	return(((i) < 64) ? (0x01010 + ((i) * 0x40)) : (0x0D010 + (((i) - 64) * 0x40)))
}

internal func IXGBE_RDT(_ i: UInt32) -> UInt32 {
	return(((i) < 64) ? (0x01018 + ((i) * 0x40)) : (0x0D018 + (((i) - 64) * 0x40)))
}

internal func IXGBE_RXDCTL(_ i: UInt32) -> UInt32 {
	return(((i) < 64) ? (0x01028 + ((i) * 0x40)) : (0x0D028 + (((i) - 64) * 0x40)))
}

internal func IXGBE_DCA_RXCTRL(_ i: UInt32) -> UInt32 {
	return (((i) <= 15) ? (0x02200 + ((i) * 4)) : (((i) < 64) ? (0x0100C + ((i) * 0x40)) : (0x0D00C + (((i) - 64) * 0x40))))
}

internal func IXGBE_TXPBSIZE(_ i: UInt32) -> UInt32 {
	return (0x0CC00 + ((i) * 4))

}
internal func IXGBE_TDBAL(_ i: UInt32) -> UInt32 {
	return (0x06000 + ((i) * 0x40)) /* 32 of them (0-31)*/
}
internal func IXGBE_TDBAH(_ i: UInt32) -> UInt32 {
	return (0x06004 + ((i) * 0x40))
}
internal func IXGBE_TDLEN(_ i: UInt32) -> UInt32 {
	return (0x06008 + ((i) * 0x40))
}
internal func IXGBE_TDH(_ i: UInt32) -> UInt32 {
	return (0x06010 + ((i) * 0x40))
}
internal func IXGBE_TDT(_ i: UInt32) -> UInt32 {
	return (0x06018 + ((i) * 0x40))
}
internal func IXGBE_TXDCTL(_ i: UInt32) -> UInt32 {
	return (0x06028 + ((i) * 0x40))
}
