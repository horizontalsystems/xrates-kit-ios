import ObjectMapper

struct ResponseCurrencyMap {
    let values: [String: Decimal]
}

struct CryptoCompareLatestRateResponse: ImmutableMappable {
    let values: [String: ResponseCurrencyMap]

    init(map: Map) throws {
        let rawDictionary = map.JSON
        let keys = rawDictionary.keys
        var values = [String: ResponseCurrencyMap]()

        for key in keys {
            values[key] = try map.value(key, using: TransformOf<ResponseCurrencyMap, [String: Double]>(fromJSON: { strings -> ResponseCurrencyMap? in
                guard let strings = strings else {
                    return nil
                }

                var result = [String: Decimal]()

                for (key, value) in strings {
                    result[key] = NSNumber(value: value).decimalValue
                }

                return ResponseCurrencyMap(values: result)
            }, toJSON: { _ in nil }))
        }
        self.values = values
    }

}
