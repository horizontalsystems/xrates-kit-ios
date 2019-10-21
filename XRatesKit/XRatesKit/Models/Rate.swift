import Foundation

public struct Rate {
    public let value: Decimal
    public let date: Date

    private let expirationInterval: TimeInterval

    init(rateRecord: LatestRate, expirationInterval: TimeInterval) {
        self.expirationInterval = expirationInterval
        self.value = rateRecord.value
        self.date = rateRecord.date
    }

    public var expired: Bool {
        Date().timeIntervalSince1970 - date.timeIntervalSince1970 > expirationInterval
    }

}

extension Rate: Equatable {

    static public func ==(lhs: Rate, rhs: Rate) -> Bool {
        lhs.value == rhs.value && lhs.date == rhs.date
    }

}
