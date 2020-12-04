import ObjectMapper
import HsToolKit

struct UniswapSubgraphEthPriceResponse: ImmutableMappable {
    let usdPrice: Decimal

    init(map: Map) throws {
        let raw = map.JSON

        guard let priceDictionary = raw["data"] as? [String: Any],
              let bundle = priceDictionary["bundle"] as? [String: Any],
              let usdPriceString = bundle["ethPriceUSD"] as? String,
              let usdPrice = Decimal(string: usdPriceString) else {
            throw NetworkManager.ObjectMapperError.mappingError
        }

        self.usdPrice = usdPrice
    }

}
