import RxSwift
import CoinKit

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
        var marketInfos = [CoinType: MarketInfo]()

        records.forEach { record in
            let info = marketInfo(record: record)
            delegate?.didUpdate(marketInfo: info, key: record.key)
            marketInfos[record.key.coinType] = info
        }

        delegate?.didUpdate(marketInfos: marketInfos, currencyCode: currencyCode)
    }

}

extension MarketInfoManager: IMarketInfoManager {

    func lastSyncTimestamp(coinTypes: [CoinType], currencyCode: String) -> TimeInterval? {
        let records = storage.marketInfoRecordsSortedByTimestamp(coinTypes: coinTypes, currencyCode: currencyCode)

        // not all records for coin codes are stored in database - force sync required
        guard records.count == coinTypes.count else {
            return nil
        }

        // return date of the most expired stored record
        return records.first?.timestamp
    }

    func marketInfo(key: PairKey) -> MarketInfo? {
        storage.marketInfoRecord(key: key).map { marketInfo(record: $0) }
    }

    func handleUpdated(records: [MarketInfoRecord], currencyCode: String) {
        storage.save(marketInfoRecords: records)
        notify(records: records, currencyCode: currencyCode)
    }

    func notifyExpired(coinTypes: [CoinType], currencyCode: String) {
        let records = storage.marketInfoRecordsSortedByTimestamp(coinTypes: coinTypes, currencyCode: currencyCode)
        notify(records: records, currencyCode: currencyCode)
    }

}
