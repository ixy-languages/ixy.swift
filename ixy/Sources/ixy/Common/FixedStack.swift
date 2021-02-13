//
//  FixedArray.swift
//  app
//
//  Created by Thomas Günzel on 17.10.2018.
//

import Foundation

/// a generic fixed stack implementation which can be used as a stand in for an array, to check performance
struct FixedStack<T> {
	var objects: [T?]
	var top: Int = 0

	init(objects: [T]) {
		self.objects = objects
		self.top = objects.count - 1
	}

	init(size: Int) {
		self.objects = Array.init(repeating: nil, count: size)
		self.top = -1
	}

	mutating func initialize(from objects: [T]) {
		for object in objects {
			self.push(object)
		}
	}

	mutating func push(_ object: T) {
		assert(top < objects.count, "stack unbalanced push")
		top += 1
		objects[top] = object
	}

	mutating func pop() -> T? {
		assert(top >= 0, "stack unbalanced pop")
		let object = objects[top]
		objects[top] = nil
		top -= 1
		return object
	}
}
