import RxSwift

class GlobalMarketInfoManager {
    private let globalMarketInfoProvider: IGlobalMarketInfoProvider
    private let storage: IGlobalMarketInfoStorage

    init(globalMarketInfoProvider: IGlobalMarketInfoProvider, storage: IGlobalMarketInfoStorage) {
        self.globalMarketInfoProvider = globalMarketInfoProvider
        self.storage = storage
    }

}

extension GlobalMarketInfoManager {

    func globalMarketInfo(currencyCode: String) -> Single<GlobalCoinMarket> {
        globalMarketInfoProvider
            .globalCoinMarketsInfo(currencyCode: currencyCode)
            .do { [weak self] globalMarketInfo in
                self?.storage.save(globalMarketInfo: globalMarketInfo)
            }
            .catchError { [weak self] error in
                guard let globalMarketInfo = self?.storage.globalMarketInfo(currencyCode: currencyCode) else {
                    return Single.error(error)
                }

                return Single.just(globalMarketInfo)
            }
    }

}
