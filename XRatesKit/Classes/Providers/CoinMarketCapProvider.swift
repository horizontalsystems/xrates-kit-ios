import RxSwift
import HsToolKit
import Alamofire

class CoinMarketCapProvider {
    private let apiKey: String
    private let marketInfoProvider: IMarketInfoProvider

    private let networkManager: NetworkManager
    private let baseUrl = "https://pro-api.coinmarketcap.com/v1/cryptocurrency"
    private let timeoutInterval: TimeInterval
    private let topMarketsCount: Int

    init(apiKey: String, marketInfoProvider: IMarketInfoProvider, networkManager: NetworkManager, timeoutInterval: TimeInterval, topMarketsCount: Int) {
        self.apiKey = apiKey
        self.marketInfoProvider = marketInfoProvider
        self.networkManager = networkManager
        self.timeoutInterval = timeoutInterval
        self.topMarketsCount = topMarketsCount
    }

    private func topMarketInfosUrl() -> String {
        "\(baseUrl)/listings/latest"
    }

}

extension CoinMarketCapProvider: ITopMarketsProvider {

    func topMarkets(currencyCode: String) -> Single<[(coin: TopMarketCoin, marketInfo: MarketInfoRecord)]> {
        let urlString = topMarketInfosUrl()
        let headers = HTTPHeaders(["X-CMC_PRO_API_KEY": apiKey])
        let parameters: Parameters = ["limit": topMarketsCount]

        let request = networkManager.session.request(urlString, method: .get, parameters: parameters, headers: headers)

        return networkManager.single(request: request)
                .flatMap { [weak self] (response: CoinMarketCapTopMarketsResponse) in
                    let coins: [XRatesKit.Coin] = response.values
                    let topMarkets: Single<[MarketInfoRecord]> = self?.marketInfoProvider.getMarketInfoRecords(coins: coins, currencyCode: currencyCode) ?? Single.just([])

                    return topMarkets.map { marketInfos in
                        var orderedMarketInfos = [(coin: TopMarketCoin, marketInfo: MarketInfoRecord)]()

                        for coin in coins {
                            guard let marketInfo = marketInfos.first(where: { $0.coinCode == coin.code }) else {
                                continue
                            }

                            orderedMarketInfos.append((coin: TopMarketCoin(code: coin.code, title: coin.title), marketInfo: marketInfo))
                        }

                        return orderedMarketInfos
                    }
                }
    }

}
