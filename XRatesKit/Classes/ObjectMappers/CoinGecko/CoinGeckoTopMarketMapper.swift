import HsToolKit
import CoinKit

class CoinGeckoTopMarketMapper: IApiMapper {
    typealias T = [CoinMarket]
    
    private let providerCoinManager: ProviderCoinsManager
    private let currencyCode: String
    private let fetchDiffPeriod: TimePeriod
    private let expirationInterval: TimeInterval
    
    init(providerCoinManager: ProviderCoinsManager, currencyCode: String, fetchDiffPeriod: TimePeriod, expirationInterval: TimeInterval) {
        self.providerCoinManager = providerCoinManager
        self.currencyCode = currencyCode
        self.fetchDiffPeriod = fetchDiffPeriod
        self.expirationInterval = expirationInterval
    }
    
    func map(statusCode: Int, data: Any?) throws -> T {
        guard let array = data as? [[String: Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }
        
        return array.compactMap { tokenData in
            guard let coinCode = tokenData["symbol"] as? String,
                  let coinTitle = tokenData["name"] as? String,
                  let externalId = tokenData["id"] as? String,
                  let coinType = providerCoinManager.coinTypes(providerId: externalId, provider: .CoinGecko).first else {
                
                return nil
            }
            
            let rate = Decimal(convertibleValue: tokenData["current_price"]) ?? 0
            let supply = Decimal(convertibleValue: tokenData["circulating_supply"]) ?? 0
            let volume = Decimal(convertibleValue: tokenData["total_volume"]) ?? 0
            let marketCap = Decimal(convertibleValue: tokenData["market_cap"]) ?? 0
            
            let priceDiffFieldName: String
            switch fetchDiffPeriod {
                case .hour1: priceDiffFieldName = "price_change_percentage_1h_in_currency"
                case .day7: priceDiffFieldName = "price_change_percentage_7d_in_currency"
                case .day30: priceDiffFieldName = "price_change_percentage_30d_in_currency"
                case .year1: priceDiffFieldName = "price_change_percentage_1y_in_currency"
                default: priceDiffFieldName = "price_change_percentage_24h"
            }
            
            let rateDiffPeriod = Decimal(convertibleValue: tokenData[priceDiffFieldName]) ?? 0
            let rateDiff24h = Decimal(convertibleValue: tokenData["price_change_percentage_24h"]) ?? 0
            
            let record = MarketInfoRecord(
                coinType: coinType,
                coinCode: coinCode.uppercased(),
                currencyCode: currencyCode,
                rate: rate,
                openDay: 0,
                diff: rateDiff24h,
                volume: volume,
                marketCap: marketCap,
                supply: supply,
                rateDiffPeriod: rateDiffPeriod
            )
            
            return CoinMarket(coinType: coinType, coinCode: coinCode.uppercased(), coinTitle: coinTitle, record: record, expirationInterval: expirationInterval)
        }
    }
    
}
