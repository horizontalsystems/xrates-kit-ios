import ObjectMapper

struct ResponseMarketInfo {
    let volume: Decimal
    let marketCap: Decimal
    let supply: Decimal
}

struct ResponseMarketInfoCurrencyMap {
    let values: [String: ResponseMarketInfo]
}

struct CryptoCompareMarketInfoResponse: ImmutableMappable {
    let values: [String: ResponseMarketInfoCurrencyMap]

    init(map: Map) throws {
        var values = [String: ResponseMarketInfoCurrencyMap]()
        let raw = map.JSON
        guard let rawDictionary = raw["RAW"] as? [String: Any] else {
            self.values = values
            return
        }
        let keys = rawDictionary.keys

        for key in keys {
            values[key] = try map.value("RAW.\(key)", using: TransformOf<ResponseMarketInfoCurrencyMap, [String: Any]>(fromJSON: { dictionary -> ResponseMarketInfoCurrencyMap? in
                guard let dictionary = dictionary else {
                    return nil
                }

                var result = [String: ResponseMarketInfo]()

                for (key, value) in dictionary {
                    if let marketInfo = value as? [String: Any],
                       let volume = marketInfo["VOLUMEDAYTO"] as? Double,
                       let marketCap = marketInfo["MKTCAP"] as? Double,
                       let supply = marketInfo["SUPPLY"] as? Double {
                        result[key] = ResponseMarketInfo(volume: NSNumber(value: volume).decimalValue, marketCap: NSNumber(value: marketCap).decimalValue, supply: NSNumber(value: supply).decimalValue)
                    }
                }

                return ResponseMarketInfoCurrencyMap(values: result)
            }, toJSON: { _ in nil }))
        }
        self.values = values
    }

}
