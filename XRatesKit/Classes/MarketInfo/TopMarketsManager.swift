import RxSwift

class TopMarketsManager {
    weak var delegate: ITopMarketsManagerDelegate?

    private let storage: IMarketInfoStorage
    private let expirationInterval: TimeInterval
    private let marketsCount: Int

    init(storage: IMarketInfoStorage, expirationInterval: TimeInterval, marketsCount: Int) {
        self.storage = storage
        self.expirationInterval = expirationInterval
        self.marketsCount = marketsCount
    }

    private func topMarketInfo(record: MarketInfoRecord) -> MarketInfo {
        MarketInfo(record: record, expirationInterval: expirationInterval)
    }

    private func notify(records: [MarketInfoRecord]) {
        let topMarketInfos = records.map { topMarketInfo(record: $0) }

        delegate?.didUpdate(topMarketInfos: topMarketInfos)
    }

}

extension TopMarketsManager: ITopMarketsManager {

    func handleUpdated(records: [MarketInfoRecord]) {
        storage.save(topMarketInfoRecords: records)
        notify(records: records)
    }

    func notifyExpired(currencyCode: String) {
        let records = storage.topMarketInfoRecordsSortedByMarketCap(currencyCode: currencyCode, limit: marketsCount)
        notify(records: records)
    }

    func topMarketInfos(currencyCode: String) -> [MarketInfo] {
        storage.topMarketInfoRecordsSortedByMarketCap(currencyCode: currencyCode, limit: marketsCount).map { topMarketInfo(record: $0) }
    }

}
