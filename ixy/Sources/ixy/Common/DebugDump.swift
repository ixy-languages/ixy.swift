//
//  DebugDump.swift
//  app
//
//  Created by Thomas Günzel on 27.09.2018.
//

import Foundation

public protocol DebugDump {
	func dump(_ inset: Int)

	func createDumpPrefix(_ inset: Int) -> String
}

extension DebugDump {
	public func createDumpPrefix(_ inset: Int) -> String {
		return inset > 0 ? String(repeating: " ", count: inset) : ""
	}
}

extension Array: DebugDump where Element : DebugDump {
	func dump(_ inset: Int = 0, elementName name: String) {
		let pre = createDumpPrefix(inset)
		for (idx,elem) in self.enumerated() {
			print("\(pre)\(name) [\(idx)]")
			elem.dump(inset + 1)
		}
	}

	public func dump(_ inset: Int = 0) {
		dump(inset, elementName: "Element")
	}
}
