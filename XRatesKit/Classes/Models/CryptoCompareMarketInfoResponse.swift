import ObjectMapper

struct ResponseMarketInfo: ImmutableMappable {
    let timestamp: TimeInterval
    let rate: Decimal
    let open24Hour: Decimal
    let diff: Decimal
    let volume: Decimal
    let marketCap: Decimal
    let supply: Decimal

    init(map: Map) throws {
        timestamp = try map.value("LASTUPDATE")
        rate = try map.value("PRICE", using: ResponseMarketInfo.decimalTransform)
        open24Hour = try map.value("OPEN24HOUR", using: ResponseMarketInfo.decimalTransform)
        diff = try map.value("CHANGEPCT24HOUR", using: ResponseMarketInfo.decimalTransform)
        volume = try map.value("VOLUME24HOURTO", using: ResponseMarketInfo.decimalTransform)
        marketCap = try map.value("MKTCAP", using: ResponseMarketInfo.decimalTransform)
        supply = try map.value("SUPPLY", using: ResponseMarketInfo.decimalTransform)
    }

    private static let decimalTransform: TransformOf<Decimal, Double> = TransformOf(fromJSON: { double -> Decimal? in
        guard let double = double else {
            return nil
        }

        return Decimal(string: "\(double)")
    }, toJSON: { _ in nil })

}

struct CryptoCompareMarketInfoResponse: ImmutableMappable {
    let values: [String: [String: ResponseMarketInfo]]

    init(map: Map) throws {
        try CryptoCompareResponse.validate(map: map)

        var values = [String: [String: ResponseMarketInfo]]()

        let raw = map.JSON

        guard let rawDictionary = raw["RAW"] as? [String: Any] else {
            throw CryptoCompareError.invalidData
        }

        for (coinCode, coinCodeValue) in rawDictionary {
            guard let coinCodeDictionary = coinCodeValue as? [String: Any] else {
                throw CryptoCompareError.invalidData
            }

            var coinCodeValues = [String: ResponseMarketInfo]()

            for (currencyCode, currencyCodeValue) in coinCodeDictionary {
                guard let currencyCodeDictionary = currencyCodeValue as? [String: Any] else {
                    throw CryptoCompareError.invalidData
                }

                coinCodeValues[currencyCode] = try ResponseMarketInfo(JSON: currencyCodeDictionary)
            }

            values[coinCode] = coinCodeValues
        }

        self.values = values
    }

}
