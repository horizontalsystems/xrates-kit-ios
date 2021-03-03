import Foundation
import HsToolKit
import RxSwift
import Alamofire
import CoinKit

class CoinGeckoProvider {
    private let disposeBag = DisposeBag()
    private let provider = InfoProvider.CoinGecko

    private let providerCoinsManager: ProviderCoinsManager
    private let networkManager: NetworkManager
    private let expirationInterval: TimeInterval
    private let coinsPerPage = 200

    init(providerCoinsManager: ProviderCoinsManager, networkManager: NetworkManager, expirationInterval: TimeInterval) {
        self.providerCoinsManager = providerCoinsManager
        self.networkManager = networkManager
        self.expirationInterval = expirationInterval
    }

    private func allCoinMarketsNextDelayedSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, page: Int, itemCount: Int?) -> Single<[CoinMarket]> {
        guard let itemCount = itemCount, itemCount > coinsPerPage else {
            return Single.just([])
        }

        let single = allCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, page: page + 1, itemCount: itemCount - coinsPerPage)

        return Single<Int>
                .timer(.seconds(1), scheduler: SerialDispatchQueueScheduler(qos: .background))
                .flatMap { _ in single }
    }

    private func allCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, page: Int = 1, itemCount: Int? = nil, coinIds: String? = nil) -> Single<[CoinMarket]> {
        var pageParams = ""
        if let itemCount = itemCount {
            let perPage = min(coinsPerPage, itemCount)
            pageParams += "&per_page=\(perPage)&page=\(page)"
        }

        let priceChangePercentage: String
        switch fetchDiffPeriod {
        case .hour24, .dayStart: priceChangePercentage = ""
        default: priceChangePercentage = "&price_change_percentage=\(fetchDiffPeriod.title)"
        }

        let url = "\(provider.baseUrl)/coins/markets?\(coinIds ?? "")&vs_currency=\(currencyCode)\(priceChangePercentage)&order=market_cap_desc\(pageParams)"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = CoinGeckoTopMarketMapper(providerCoinManager: providerCoinsManager, currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, expirationInterval: expirationInterval)
        return networkManager.single(request: request, mapper: mapper)
                .flatMap { [weak self] coinMarkets -> Single<[CoinMarket]> in
                    let single = self?.allCoinMarketsNextDelayedSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, page: page, itemCount: itemCount) ?? Single.just([])
                    return single.map { nextCoinMarkets -> [CoinMarket] in coinMarkets + nextCoinMarkets }
                }
    }

}

extension CoinGeckoProvider {

    func globalDefiMarketCap(currencyCode: String) -> Single<Decimal> {
        let url = "\(provider.baseUrl)/global/decentralized_finance_defi"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = CoinGeckoDefiMarketCapMapper()
        return networkManager.single(request: request, mapper: mapper)
    }

    func coinMarketInfoSingle(coinType: CoinType, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinGeckoCoinMarketInfoMapper.CoinGeckoCoinInfoResponse> {
        guard let externalId = providerCoinsManager.providerId(coinType: coinType, provider: .CoinGecko) else {
            return Single.error(ProviderCoinsManager.ExternalIdError.noMatchingCoinId)
        }

        let url = "\(provider.baseUrl)/coins/\(externalId)?localization=false&tickers=false&developer_data=false&sparkline=false"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = CoinGeckoCoinMarketInfoMapper(coinType: coinType, currencyCode: currencyCode.lowercased(), timePeriods: rateDiffTimePeriods, rateDiffCoinCodes: rateDiffCoinCodes.map { $0.lowercased() })
        return networkManager.single(request: request, mapper: mapper)
    }

    func topCoinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]> {
        allCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemCount)
    }

    func coinMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, coinTypes: [CoinType]) -> Single<[CoinMarket]> {
        let externalIds = coinTypes.compactMap { providerCoinsManager.providerId(coinType: $0, provider: .CoinGecko) }

        return allCoinMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, coinIds: "&ids=\(externalIds.joined(separator: ","))")
    }

}
