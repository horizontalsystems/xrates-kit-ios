import ObjectMapper

struct CryptoCompareTopMarketInfosResponse: ImmutableMappable {
    let values: [String: [(coinCode: String, coinName: String, marketInfo: ResponseMarketInfo)]]

    init(map: Map) throws {
        try CryptoCompareResponse.validate(map: map)

        var values = [String: [(coinCode: String, coinName: String, marketInfo: ResponseMarketInfo)]]()
        let raw = map.JSON

        guard let rawArray = raw["Data"] as? [Any] else {
            throw CryptoCompareError.invalidData
        }

        for marketElement in rawArray {
            guard let marketDictionary = marketElement as? [String: Any],
                  let coinInfoDictionary = marketDictionary["CoinInfo"] as? [String: Any], 
                  let pricesDictionary = marketDictionary["RAW"] as? [String: Any] else {
                throw CryptoCompareError.invalidData
            }

            guard let coinCode = coinInfoDictionary["Name"] as? String,
                  let coinName = coinInfoDictionary["FullName"] as? String else {
                throw CryptoCompareError.invalidData
            }

            for (currencyCode, currencyCodeValue) in pricesDictionary {
                if values[currencyCode] == nil {
                    values[currencyCode] = [(coinCode: String, coinName: String, marketInfo: ResponseMarketInfo)]()
                }

                guard let currencyCodeDictionary = currencyCodeValue as? [String: Any] else {
                    throw CryptoCompareError.invalidData
                }

                let marketInfo = try ResponseMarketInfo(JSON: currencyCodeDictionary)

                values[currencyCode]?.append((coinCode: coinCode, coinName: coinName, marketInfo: marketInfo))
            }
        }

        self.values = values
    }
    
}
