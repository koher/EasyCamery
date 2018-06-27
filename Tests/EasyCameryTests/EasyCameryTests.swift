import XCTest
@testable import EasyCamery

final class EasyCameryTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(EasyCamery().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
