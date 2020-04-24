import RxSwift

class TopMarketsManager {
    weak var delegate: ITopMarketsManagerDelegate?

    private let storage: ITopMarketsStorage
    private let expirationInterval: TimeInterval

    init(storage: ITopMarketsStorage, expirationInterval: TimeInterval) {
        self.storage = storage
        self.expirationInterval = expirationInterval
    }

    private func topMarketInfo(record: TopMarketInfoRecord) -> TopMarketInfo {
        TopMarketInfo(record: record, expirationInterval: expirationInterval)
    }

    private func notify(records: [TopMarketInfoRecord]) {
        let topMarketInfos = records.map { topMarketInfo(record: $0) }

        delegate?.didUpdate(topMarketInfos: topMarketInfos)
    }

}

extension TopMarketsManager: ITopMarketsManager {

    func lastSyncTimestamp(currencyCode: String) -> TimeInterval? {
        let records = storage.topMarketInfoRecords(currencyCode: currencyCode)

        // return date of the most expired stored record
        return records.first?.timestamp
    }

    func handleUpdated(records: [TopMarketInfoRecord]) {
        storage.save(topMarketInfoRecords: records)
        notify(records: records)
    }

    func notifyExpired(currencyCode: String) {
        let records = storage.topMarketInfoRecords(currencyCode: currencyCode)
        notify(records: records)
    }

    func topMarketInfos(currencyCode: String) -> [TopMarketInfo] {
        storage.topMarketInfoRecords(currencyCode: currencyCode).map { topMarketInfo(record: $0) }
    }

}
