//
//  Subcommand.swift
//  app
//
//  Created by Thomas Günzel on 28.10.2018.
//

import Foundation

enum SubcommandError: Error {
	case notEnoughArguments
	case argumentError(String)
}

protocol Subcommand {
	init(arguments: [String]) throws
	func loop()

	static var usage: String { get }
}
