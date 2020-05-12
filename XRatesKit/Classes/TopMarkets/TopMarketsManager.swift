import RxSwift
import HsToolKit

class TopMarketsManager {
    weak var delegate: ITopMarketsManagerDelegate?

    private let storage: ITopMarketsStorage
    private let provider: ITopMarketsProvider
    private let expirationInterval: TimeInterval
    private let marketsCount: Int

    init(storage: ITopMarketsStorage, provider: ITopMarketsProvider, expirationInterval: TimeInterval, marketsCount: Int) {
        self.storage = storage
        self.provider = provider
        self.expirationInterval = expirationInterval
        self.marketsCount = marketsCount
    }

    private func topMarket(coin: TopMarketCoin, marketInfo: MarketInfoRecord) -> TopMarket {
        TopMarket(coin: coin, record: marketInfo, expirationInterval: expirationInterval)
    }

}

extension TopMarketsManager: ITopMarketsManager {

    func topMarketInfos(currencyCode: String) -> Single<[TopMarket]> {
        provider.topMarkets(currencyCode: currencyCode)
                .do(onSuccess: { [weak self] tuples in self?.storage.save(topMarkets: tuples) })
                .map { tuples in tuples.map { self.topMarket(coin: $0.coin, marketInfo: $0.marketInfo) }}
                .catchError { [weak self] error in
                    guard let manager = self else {
                        return Single.error(error)
                    }

                    if let requestError = error as? NetworkManager.RequestError, case let .noResponse(_) = requestError {
                        let topMarkets = manager.storage.topMarkets(currencyCode: currencyCode, limit: manager.marketsCount).map {
                            manager.topMarket(coin: $0.coin, marketInfo: $0.marketInfo)
                        }

                        return Single.just(topMarkets)
                    }

                    return Single.error(error)
                }
    }

}
