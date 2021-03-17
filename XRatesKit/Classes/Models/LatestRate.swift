import Foundation
import CoinKit

public struct LatestRate {
    public let coinType: CoinType
    public let currencyCode: String
    public let rate: Decimal
    public let rateDiff24h: Decimal
    public let timestamp: TimeInterval

    private let expirationInterval: TimeInterval

    init(record: LatestRateRecord, expirationInterval: TimeInterval) {
        coinType = record.coinType
        currencyCode = record.currencyCode
        rate = record.rate
        rateDiff24h = record.rateDiff24h
        timestamp = record.timestamp

        self.expirationInterval = expirationInterval
    }

    public var expired: Bool {
        Date().timeIntervalSince1970 - timestamp > expirationInterval
    }

}
