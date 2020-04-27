import RxSwift

class MarketInfoManager {
    weak var delegate: IMarketInfoManagerDelegate?

    private let storage: IMarketInfoStorage
    private let expirationInterval: TimeInterval

    init(storage: IMarketInfoStorage, expirationInterval: TimeInterval) {
        self.storage = storage
        self.expirationInterval = expirationInterval
    }

    private func marketInfo(record: MarketInfoRecord) -> MarketInfo {
        MarketInfo(record: record, expirationInterval: expirationInterval)
    }

    private func notify(records: [MarketInfoRecord], currencyCode: String) {
        var marketInfos = [String: MarketInfo]()

        records.forEach { record in
            let info = marketInfo(record: record)
            delegate?.didUpdate(marketInfo: info, key: record.key)
            marketInfos[record.key.coinCode] = info
        }

        delegate?.didUpdate(marketInfos: marketInfos, currencyCode: currencyCode)
    }

}

extension MarketInfoManager: IMarketInfoManager {

    func marketInfo(key: PairKey) -> MarketInfo? {
        storage.marketInfoRecord(key: key).map { marketInfo(record: $0) }
    }

    func handleUpdated(records: [MarketInfoRecord], currencyCode: String) {
        storage.save(marketInfoRecords: records)
        notify(records: records, currencyCode: currencyCode)
    }

    func notifyExpired(coinCodes: [String], currencyCode: String) {
        let records = storage.marketInfoRecordsSortedByTimestamp(coinCodes: coinCodes, currencyCode: currencyCode)
        notify(records: records, currencyCode: currencyCode)
    }

}
