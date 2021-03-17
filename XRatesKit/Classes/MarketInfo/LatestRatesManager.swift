import RxSwift
import CoinKit

class LatestRatesManager {
    weak var delegate: ILatestRatesManagerDelegate?

    private let storage: ILatestRatesStorage
    private let expirationInterval: TimeInterval

    init(storage: ILatestRatesStorage, expirationInterval: TimeInterval) {
        self.storage = storage
        self.expirationInterval = expirationInterval
    }

    private func latestRate(record: LatestRateRecord) -> LatestRate {
        LatestRate(record: record, expirationInterval: expirationInterval)
    }

    private func notify(records: [LatestRateRecord], currencyCode: String) {
        var marketInfos = [CoinType: LatestRate]()

        records.forEach { record in
            let rate = latestRate(record: record)
            delegate?.didUpdate(latestRate: rate, key: record.key)
            marketInfos[record.key.coinType] = rate
        }

        delegate?.didUpdate(latestRates: marketInfos, currencyCode: currencyCode)
    }

}

extension LatestRatesManager: ILatestRatesManager {

    func lastSyncTimestamp(coinTypes: [CoinType], currencyCode: String) -> TimeInterval? {
        let records = storage.latestRateRecordsSortedByTimestamp(coinTypes: coinTypes, currencyCode: currencyCode)

        // not all records for coin codes are stored in database - force sync required
        guard records.count == coinTypes.count else {
            return nil
        }

        // return date of the most expired stored record
        return records.first?.timestamp
    }

    func latestRate(key: PairKey) -> LatestRate? {
        storage.latestRateRecord(key: key).map { latestRate(record: $0) }
    }

    func handleUpdated(records: [LatestRateRecord], currencyCode: String) {
        storage.save(marketInfoRecords: records)
        notify(records: records, currencyCode: currencyCode)
    }

    func notifyExpired(coinTypes: [CoinType], currencyCode: String) {
        let records = storage.latestRateRecordsSortedByTimestamp(coinTypes: coinTypes, currencyCode: currencyCode)
        notify(records: records, currencyCode: currencyCode)
    }

}
