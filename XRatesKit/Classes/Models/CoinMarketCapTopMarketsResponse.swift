import ObjectMapper
import HsToolKit

struct CoinMarketCapTopMarketsResponse: ImmutableMappable {
    let values: [Coin]

    init(map: Map) throws {
        let raw = map.JSON

        guard let rawArray = raw["data"] as? [Any] else {
            throw NetworkManager.ObjectMapperError.mappingError
        }

        values = try rawArray.map { marketElement in
            guard let marketDictionary = marketElement as? [String: Any],
                  let code = marketDictionary["symbol"] as? String,
                  let title = marketDictionary["name"] as? String else {
                throw NetworkManager.ObjectMapperError.mappingError
            }

            return Coin(code: code, title: title)
        }
    }

}
