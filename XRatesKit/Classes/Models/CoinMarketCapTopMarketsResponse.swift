import ObjectMapper
import HsToolKit

struct CoinMarketCapTopMarketsResponse: ImmutableMappable {
    let values: [XRatesKit.Coin]

    init(map: Map) throws {
        let raw = map.JSON

        guard let rawArray = raw["data"] as? [Any] else {
            throw NetworkManager.ObjectMapperError.mappingError
        }

        values = try rawArray.map { marketElement in
            guard let marketDictionary = marketElement as? [String: Any] else {
                throw NetworkManager.ObjectMapperError.mappingError
            }

            guard let code = marketDictionary["symbol"] as? String,
                  let title = marketDictionary["name"] as? String else {
                throw NetworkManager.ObjectMapperError.mappingError
            }

            var coinType: XRatesKit.CoinType? = nil

            if let platform = marketDictionary["platform"] as? [String: Any],
               let token_address = platform["token_address"] as? String,
               let name = platform["name"] as? String, name == "Ethereum" {
                coinType = .erc20(address: token_address)
            } else if let slug = marketDictionary["slug"] as? String, slug == "ethereum" {
                coinType = .ethereum
            }

            return XRatesKit.Coin(code: code, title: title, type: coinType)
        }
    }

}
