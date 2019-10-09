import Foundation

public struct RateInfo {
    public let coinCode: String
    public let currencyCode: String
    public let value: Decimal
    public let date: Date

    init(_ rate: Rate) {
        self.coinCode = rate.coinCode
        self.currencyCode = rate.currencyCode
        self.value = rate.value
        self.date = rate.date
    }

}

extension RateInfo: Equatable {
    static public func ==(lhs: RateInfo, rhs: RateInfo) -> Bool {
        lhs.value == rhs.value && lhs.coinCode == rhs.coinCode && lhs.currencyCode == rhs.currencyCode && lhs.date == rhs.date
    }
}
