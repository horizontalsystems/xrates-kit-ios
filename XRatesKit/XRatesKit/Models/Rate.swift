import Foundation

public struct Rate {
    public let value: Decimal
    public let timestamp: TimeInterval

    private let expirationInterval: TimeInterval

    init(rateRecord: LatestRate, expirationInterval: TimeInterval) {
        self.expirationInterval = expirationInterval
        self.value = rateRecord.value
        self.timestamp = rateRecord.timestamp
    }

    public var expired: Bool {
        Date().timeIntervalSince1970 - timestamp > expirationInterval
    }

}

extension Rate: Equatable {

    static public func ==(lhs: Rate, rhs: Rate) -> Bool {
        lhs.value == rhs.value && lhs.timestamp == rhs.timestamp
    }

}
