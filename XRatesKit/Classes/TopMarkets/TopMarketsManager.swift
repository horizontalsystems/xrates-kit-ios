import RxSwift
import HsToolKit

class TopMarketsManager {
    weak var delegate: ITopMarketsManagerDelegate?

    private let storage: ITopMarketsStorage
    private let topProvider: ITopMarketsProvider
    private let topDefiProvider: ITopDefiMarketsProvider
    private let expirationInterval: TimeInterval
    private let marketsCount: Int

    init(storage: ITopMarketsStorage, topProvider: ITopMarketsProvider, topDefiProvider: ITopDefiMarketsProvider, expirationInterval: TimeInterval, marketsCount: Int) {
        self.storage = storage
        self.topProvider = topProvider
        self.topDefiProvider = topDefiProvider
        self.expirationInterval = expirationInterval
        self.marketsCount = marketsCount
    }

    private func topMarket(coin: TopMarketCoin, marketInfo: MarketInfoRecord) -> TopMarket {
        TopMarket(coin: XRatesKit.Coin(code: coin.code, title: coin.title, type: nil), record: marketInfo, expirationInterval: expirationInterval)
    }

}

extension TopMarketsManager: ITopMarketsManager {

    func topMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemsCount: Int) -> Single<[TopMarket]> {
        topProvider.topMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemCount: itemsCount)
    }

    func topDefiMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemsCount: Int) -> Single<[TopMarket]> {
        topDefiProvider.topDefiMarketsSingle(currencyCode: currencyCode, fetchDiffPeriod: fetchDiffPeriod, itemsCount: itemsCount)
    }

}
