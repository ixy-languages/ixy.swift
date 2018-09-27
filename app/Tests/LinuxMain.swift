import XCTest

import appTests

var tests = [XCTestCaseEntry]()
tests += appTests.allTests()
XCTMain(tests)