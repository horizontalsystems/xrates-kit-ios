import Foundation

public struct MarketInfo {
    public let timestamp: TimeInterval
    public let rate: Decimal
    public let open24hour: Decimal
    public let diff: Decimal
    public let volume: Decimal
    public let marketCap: Decimal
    public let supply: Decimal

    private let expirationInterval: TimeInterval

    init(record: MarketInfoRecord, expirationInterval: TimeInterval) {
        timestamp = record.timestamp
        rate = record.rate
        open24hour = record.open24Hour
        diff = record.diff
        volume = record.volume
        marketCap = record.marketCap
        supply = record.supply

        self.expirationInterval = expirationInterval
    }

    init(timestamp: TimeInterval, rate: Decimal, open24hour: Decimal, diff: Decimal, volume: Decimal, marketCap: Decimal, supply: Decimal, expirationInterval: TimeInterval) {
        self.timestamp = timestamp
        self.rate = rate
        self.open24hour = open24hour
        self.diff = diff
        self.volume = volume
        self.marketCap = marketCap
        self.supply = supply
        self.expirationInterval = expirationInterval
    }

    public var expired: Bool {
        Date().timeIntervalSince1970 - timestamp > expirationInterval
    }

}
