import XCTest
@testable import ixy

final class ixyTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ixy().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
