import Foundation

public struct DefiTvl {
    public let data: CoinData
    public let tvl: Decimal
    public let tvlRank: Int
    public let tvlDiff: Decimal
    public let chains: [String]
}

public struct DefiTvlInfo {
    public let tvl: Decimal
    public let tvlRank: Int?
    public let tvlRatio: Decimal?
}
