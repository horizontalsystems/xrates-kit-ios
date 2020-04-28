import Foundation

public struct MarketInfo {
    public let coinCode: String
    public let coinName: String
    public let timestamp: TimeInterval
    public let rate: Decimal
    public let open24hour: Decimal
    public let diff: Decimal
    public let volume: Decimal
    public let marketCap: Decimal
    public let supply: Decimal

    private let expirationInterval: TimeInterval

    init(record: MarketInfoRecord, expirationInterval: TimeInterval) {
        coinCode = record.coinCode
        coinName = record.coinName
        timestamp = record.timestamp
        rate = record.rate
        open24hour = record.open24Hour
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
