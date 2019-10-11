struct RateSubjectKey {
    let coinCode: String
    let currencyCode: String
}

extension RateSubjectKey: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(coinCode)
        hasher.combine(currencyCode)
    }

    public static func ==(lhs: RateSubjectKey, rhs: RateSubjectKey) -> Bool {
        lhs.coinCode == rhs.coinCode && lhs.currencyCode == rhs.currencyCode
    }

}
