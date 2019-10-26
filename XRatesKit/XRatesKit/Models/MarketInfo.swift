import Foundation

public struct MarketInfo {
    public let timestamp: TimeInterval
    public let rate: Decimal
    public let diff: Decimal
    public let volume: Decimal
    public let marketCap: Decimal
    public let supply: Decimal

    private let expirationInterval: TimeInterval

    init(record: MarketInfoRecord, expirationInterval: TimeInterval) {
        timestamp = record.timestamp
        rate = record.rate
        diff = record.diff
        volume = record.volume
        marketCap = record.marketCap
        supply = record.supply

        self.expirationInterval = expirationInterval
    }

    public var expired: Bool {
        Date().timeIntervalSince1970 - timestamp > expirationInterval
    }

}
