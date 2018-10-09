//
//  LinkSpeed.swift
//  ixy
//
//  Created by Thomas Günzel on 01.10.2018.
//

import Foundation

internal enum LinkSpeed {
	case mbit100
	case gbit1
	case gbit10
}

extension LinkSpeed: CustomStringConvertible {
	var description: String {
		switch self {
		case .mbit100:
			return "100Mbit/s"
		case .gbit1:
			return "1Gbit/s"
		case .gbit10:
			return "10Gbit/s"
		}
	}
}

