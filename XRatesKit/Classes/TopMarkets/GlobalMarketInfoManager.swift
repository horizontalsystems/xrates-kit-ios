import RxSwift

class GlobalMarketInfoManager {
    private let globalMarketInfoProvider: CoinPaprikaProvider
    private let defiMarketCapProvider: CoinGeckoProvider
    private let storage: IGlobalMarketInfoStorage

    init(globalMarketInfoProvider: CoinPaprikaProvider, defiMarketCapProvider: CoinGeckoProvider, storage: IGlobalMarketInfoStorage) {
        self.globalMarketInfoProvider = globalMarketInfoProvider
        self.defiMarketCapProvider = defiMarketCapProvider
        self.storage = storage
    }

}

extension GlobalMarketInfoManager {

    func globalMarketInfo(currencyCode: String) -> Single<GlobalCoinMarket> {
        Single.zip(
        globalMarketInfoProvider.globalCoinMarketsInfo(currencyCode: currencyCode),
        defiMarketCapProvider.globalDefiMarketCap(currencyCode: currencyCode)
        ).map { marketInfo, defiMarketCap in
            marketInfo.defiMarketCap = defiMarketCap
            return marketInfo
        }.do { [weak self] globalMarketInfo in
                self?.storage.save(globalMarketInfo: globalMarketInfo)
        }.catchError { [weak self] error in
            guard let globalMarketInfo = self?.storage.globalMarketInfo(currencyCode: currencyCode) else {
                return Single.error(error)
            }

            return Single.just(globalMarketInfo)
        }
    }

}
