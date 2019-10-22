import Foundation
import XCTest
import Cuckoo
@testable import XRatesKit

extension LatestRate {

    static func mock(coinCode: String? = nil, currencyCode: String? = nil, value: Decimal? = nil, date: Date? = nil, isLatest: Bool = false) -> LatestRate {
        let uuid = UUID().uuidString
        let randomNumber = Int.random(in: 0..<100000)
        let randomDecimal = NSNumber(value: randomNumber).decimalValue
        return RateRecord(coinCode: coinCode ?? uuid, currencyCode: currencyCode ?? uuid, value: randomDecimal, date: Date(timeIntervalSince1970: TimeInterval(randomNumber)), isLatest: isLatest)
    }

}

extension XCTestCase {

    func waitForMainQueue() {
        let e = expectation(description: "Wait for Main Queue")
        DispatchQueue.main.async { e.fulfill() }
        waitForExpectations(timeout: 2)
    }

}

enum TestError: Error {
    case defaultError
}
