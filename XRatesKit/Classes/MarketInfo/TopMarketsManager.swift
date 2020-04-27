import RxSwift

class TopMarketsManager {
    weak var delegate: ITopMarketsManagerDelegate?

    private let storage: IMarketInfoStorage
    private let expirationInterval: TimeInterval

    init(storage: IMarketInfoStorage, expirationInterval: TimeInterval) {
        self.storage = storage
        self.expirationInterval = expirationInterval
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
        let records = storage.topMarketInfoRecords(currencyCode: currencyCode)
        notify(records: records)
    }

    func topMarketInfos(currencyCode: String) -> [MarketInfo] {
        storage.topMarketInfoRecords(currencyCode: currencyCode).map { topMarketInfo(record: $0) }
    }

}
