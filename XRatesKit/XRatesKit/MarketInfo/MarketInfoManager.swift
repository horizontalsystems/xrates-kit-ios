import RxSwift

class MarketInfoManager {
    private let storage: IMarketInfoStorage
    private let provider: IMarketInfoProvider

    init(storage: IMarketInfoStorage, provider: IMarketInfoProvider) {
        self.storage = storage
        self.provider = provider
    }

}

extension MarketInfoManager: IMarketInfoManager {

    func marketInfoSingle(coinCode: String, currencyCode: String) -> Single<MarketInfo> {
        let currentTimestamp = Date().timeIntervalSince1970
        let expirationInterval: TimeInterval = 60 * 60
        let fallbackInterval: TimeInterval = 24 * 60 * 60

        let storedRecord = storage.marketInfo(coinCode: coinCode, currencyCode: currencyCode)

        if let storedRecord = storedRecord, currentTimestamp - storedRecord.timestamp < expirationInterval {
            return Single.just(MarketInfo(record: storedRecord))
        }

        var single = provider.getMarketInfo(coinCode: coinCode, currencyCode: currencyCode)
                .do(onSuccess: { [weak self] record in
                    self?.storage.save(marketInfoRecord: record)
                })

        if let storedRecord = storedRecord, currentTimestamp - storedRecord.timestamp < fallbackInterval {
            single = single.catchErrorJustReturn(storedRecord)
        }

        return single.map { record in
            MarketInfo(record: record)
        }
    }

}
