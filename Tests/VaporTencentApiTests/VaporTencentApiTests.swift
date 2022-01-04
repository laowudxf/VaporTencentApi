import XCTest
@testable import VaporTencentApi
@testable import Vapor

final class VaporTencentApiTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let api = VaporTencentApi<STSPayload>.init(logger: Logger.init(label: "123"))
        api.region = ""
    }
}
