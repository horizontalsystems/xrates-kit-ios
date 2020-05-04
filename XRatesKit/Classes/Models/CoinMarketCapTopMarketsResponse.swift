import ObjectMapper

struct CoinMarketCapTopMarketsResponse: ImmutableMappable {
    let values: [Coin]

    init(map: Map) throws {
        let raw = map.JSON

        guard let rawArray = raw["data"] as? [Any] else {
            throw CryptoCompareError.invalidData
        }

        values = try rawArray.map { marketElement in
            guard let marketDictionary = marketElement as? [String: Any],
                  let code = marketDictionary["symbol"] as? String,
                  let title = marketDictionary["name"] as? String else {
                throw CryptoCompareError.invalidData
            }

            return Coin(code: code, title: title)
        }
    }

}
