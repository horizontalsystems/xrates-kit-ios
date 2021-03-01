import HsToolKit

class CoinGeckoDefiMarketCapMapper: IApiMapper {
    typealias T = Decimal
    
    func map(statusCode: Int, data: Any?) throws -> T {
        guard let dictionary = data as? [String: Any],
              let defiData = dictionary["data"] as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }
        
        return Decimal(convertibleValue: defiData["defi_market_cap"]) ?? 0
    }
    
}
