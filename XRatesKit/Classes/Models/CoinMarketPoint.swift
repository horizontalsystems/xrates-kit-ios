import Foundation
import CoinKit

public struct CoinMarketPoint {
    public let timestamp: TimeInterval
    public let marketCap: Decimal
    public let volume24h: Decimal
}
