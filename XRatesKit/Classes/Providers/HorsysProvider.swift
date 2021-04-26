import RxSwift
import HsToolKit
import Alamofire
import CoinKit

class HorsysProvider {

    let networkManager: NetworkManager
    private let provider = InfoProvider.horsys
    private let providerCoinsManager: ProviderCoinsManager

    init(networkManager: NetworkManager, providerCoinsManager: ProviderCoinsManager) {
        self.networkManager = networkManager
        self.providerCoinsManager = providerCoinsManager
    }

    private func isSupportedPeriod(timePeriod: TimePeriod) -> Bool {
        switch timePeriod {
        case .all, .dayStart,.year1, .day200: return false
        default: return true
        }
    }

}

extension HorsysProvider: IGlobalCoinMarketProvider {

    func globalCoinMarketPoints(currencyCode: String, timePeriod: TimePeriod) -> Single<[GlobalCoinMarketPoint]> {
        guard isSupportedPeriod(timePeriod: timePeriod) else {
            return Single.error(GlobalCoinMarketError.unsupportedPeriod)
        }

        let url = "\(provider.baseUrl)/markets/global/\(timePeriod.title)?currency_code=\(currencyCode)"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = GlobalCoinMarketPointMapper(timePeriod: timePeriod)
        return networkManager.single(request: request, mapper: mapper)
    }

}

extension HorsysProvider: IDefiMarketsProvider {

    func topDefiTvl(currencyCode: String, timePeriod: TimePeriod, itemCount: Int) -> Single<[DefiTvl]> {
        let period = (isSupportedPeriod(timePeriod: timePeriod) ? timePeriod : .hour24).title

        let url = "\(provider.baseUrl)/markets/defi?currency_code=\(currencyCode)&diff_period=\(period)"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        let mapper = DefiTvlArrayMapper(providerCoinsManager: providerCoinsManager, period: period)
        return networkManager
                .single(request: request, mapper: mapper)
                .map { result in
                    result.sorted {
                        $0.tvl < $1.tvl
                    }
                }
    }

    func defiTvl(coinType: CoinType, currencyCode: String) -> Single<DefiTvl> {
        guard let coinGeckoId = providerCoinsManager.providerId(coinType: coinType, provider: .coinGecko) else {
            return Single.error(ProviderCoinsManager.ExternalIdError.noMatchingCoinId)
        }

        let url = "\(provider.baseUrl)markets/defi/\(coinGeckoId)/latest?currency_code=\(currencyCode)"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())
        let mapper = DefiTvlMapper(providerCoinsManager: providerCoinsManager, period: nil)

        return networkManager.single(request: request, mapper: mapper)
    }

    func defiTvlPoints(coinType: CoinType, currencyCode: String, timePeriod: TimePeriod) -> Single<[DefiTvlPoint]> {
        fatalError("defiTvlPoints(coinType:currencyCode:timePeriod:) has not been implemented")
    }

}

extension HorsysProvider {

    enum GlobalCoinMarketError: Error {
        case unsupportedPeriod
    }

}
