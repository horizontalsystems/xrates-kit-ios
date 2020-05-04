import RxSwift

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

    func getTopMarketInfoRecords(currencyCode: String) -> Single<[MarketInfoRecord]> {
        let urlString = topMarketInfosUrl()
        let headers: [String: String] = ["X-CMC_PRO_API_KEY": "51a3a136-adc9-4e38-8fc2-8c175c810e74"]
        let parameters: [String: Any] = ["limit": topMarketsCount]

        let single: Single<[MarketInfoRecord]> = networkManager.single(urlString: urlString, httpMethod: .get, headers: headers, parameters: parameters, timoutInterval: timeoutInterval)
                .flatMap { [weak self] (response: CoinMarketCapTopMarketsResponse) in
                    let coins: [Coin] = response.values
                    let marketInfosSingle: Single<[MarketInfoRecord]> = self?.marketInfoProvider.getMarketInfoRecords(coinCodes: coins.map { $0.code }, currencyCode: currencyCode) ?? Single.just([])

                    return marketInfosSingle.map { marketInfos in
                        var orderedMarketInfos = [MarketInfoRecord]()

                        for coin in coins {
                            guard let marketInfo = marketInfos.first(where: { $0.coinCode == coin.code }) else {
                                continue
                            }

                            marketInfo.coinName = coin.title

                            orderedMarketInfos.append(marketInfo)
                        }

                        return orderedMarketInfos
                    }
                }

        return single
    }

}
