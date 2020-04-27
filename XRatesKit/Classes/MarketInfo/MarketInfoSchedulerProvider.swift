import RxSwift

class MarketInfoSchedulerProvider {
    private var coinCodes: [String]
    private let currencyCode: String
    private let storage: IMarketInfoStorage

    let expirationInterval: TimeInterval
    let retryInterval: TimeInterval

    init(coinCodes: [String], currencyCode: String, storage: IMarketInfoStorage, expirationInterval: TimeInterval, retryInterval: TimeInterval) {
        self.coinCodes = coinCodes
        self.currencyCode = currencyCode
        self.storage = storage
        self.expirationInterval = expirationInterval
        self.retryInterval = retryInterval
    }

}

extension MarketInfoSchedulerProvider: IMarketInfoSchedulerProvider {

    var lastSyncTimestamp: TimeInterval? {
        let records = storage.marketInfoRecordsSortedByTimestamp(coinCodes: coinCodes, currencyCode: currencyCode)

        // not all records for coin codes are stored in database - force sync required
        guard records.count == coinCodes.count else {
            return nil
        }

        // return date of the most expired stored record
        return records.first?.timestamp
    }

}
