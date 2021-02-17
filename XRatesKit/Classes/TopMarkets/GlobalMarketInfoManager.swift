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
        ).map { globalMarketOverview, defiMarketOverview in
            GlobalCoinMarket(
                    currencyCode: currencyCode,
                    volume24h: globalMarketOverview.volume24h,
                    volume24hDiff24h: globalMarketOverview.volume24hDiff24h,
                    marketCap: globalMarketOverview.marketCap,
                    marketCapDiff24h: globalMarketOverview.marketCapDiff24h,
                    btcDominance: globalMarketOverview.btcDominance,
                    btcDominanceDiff24h: globalMarketOverview.btcDominanceDiff24h,
                    defiMarketCap: defiMarketOverview.defiMarketCap,
                    defiMarketCapDiff24h: defiMarketOverview.defiMarketCapDiff24h,
                    defiTvl: defiMarketOverview.defiTvl,
                    defiTvlDiff24h: defiMarketOverview.defiTvlDiff24h

            )
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
