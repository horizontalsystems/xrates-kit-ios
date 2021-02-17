import RxSwift

class GlobalMarketInfoManager {
    private let globalMarketInfoProvider: CoinPaprikaProvider
    private let defiMarketCapProvider: HorsysProvider
    private let storage: IGlobalMarketInfoStorage

    init(globalMarketInfoProvider: CoinPaprikaProvider, defiMarketCapProvider: HorsysProvider, storage: IGlobalMarketInfoStorage) {
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
        ).map { marketInfo, defiMarket in
            marketInfo.defiMarketCap = defiMarket.defiMarketCap
            marketInfo.defiMarketCapDiff24h = defiMarket.defiMarketCapDiff24h
            marketInfo.defiTvl = defiMarket.defiTvl
            marketInfo.defiTvlDiff24h = defiMarket.defiTvlDiff24h
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
