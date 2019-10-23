import Foundation

public struct MarketInfo {
    public let timestamp: TimeInterval
    public let volume: Decimal
    public let marketCap: Decimal
    public let supply: Decimal

    init(record: MarketInfoRecord) {
        self.timestamp = record.timestamp
        self.volume = record.volume
        self.marketCap = record.marketCap
        self.supply = record.supply
    }

}
