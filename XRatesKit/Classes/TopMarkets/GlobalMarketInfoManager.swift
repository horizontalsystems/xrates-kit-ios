import RxSwift

class GlobalMarketInfoManager {
    private let globalMarketInfoProvider: CoinPaprikaProvider
    private let defiMarketCapProvider: HorsysProvider
    private let fiatXRatesProvider: IFiatXRatesProvider
    private let storage: IGlobalMarketInfoStorage

    init(globalMarketInfoProvider: CoinPaprikaProvider, defiMarketCapProvider: HorsysProvider, fiatXRatesProvider: IFiatXRatesProvider, storage: IGlobalMarketInfoStorage) {
        self.globalMarketInfoProvider = globalMarketInfoProvider
        self.defiMarketCapProvider = defiMarketCapProvider
        self.fiatXRatesProvider = fiatXRatesProvider
        self.storage = storage
    }

}

extension GlobalMarketInfoManager {

    func globalMarketInfo(currencyCode: String) -> Single<GlobalCoinMarket> {
        Single.zip(
                globalMarketInfoProvider.globalCoinMarketsInfo(),
                defiMarketCapProvider.globalDefiMarketCap(),
                fiatXRatesProvider.latestFiatXRates(sourceCurrency: "USD", targetCurrency: currencyCode)
        ).map { globalMarketOverview, defiMarketOverview, fiatXRate in
            GlobalCoinMarket(
                    currencyCode: currencyCode,
                    volume24h: globalMarketOverview.volume24h * fiatXRate,
                    volume24hDiff24h: globalMarketOverview.volume24hDiff24h,
                    marketCap: globalMarketOverview.marketCap * fiatXRate,
                    marketCapDiff24h: globalMarketOverview.marketCapDiff24h,
                    btcDominance: globalMarketOverview.btcDominance,
                    btcDominanceDiff24h: globalMarketOverview.btcDominanceDiff24h,
                    defiMarketCap: defiMarketOverview.defiMarketCap * fiatXRate,
                    defiMarketCapDiff24h: defiMarketOverview.defiMarketCapDiff24h,
                    defiTvl: defiMarketOverview.defiTvl * fiatXRate,
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
