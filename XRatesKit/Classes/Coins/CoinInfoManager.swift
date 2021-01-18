import RxSwift

class CoinInfoManager {
    private let disposeBag = DisposeBag()

    private let coinInfoProvider: ICoinInfoProvider
    private let storage: ICoinInfoStorage & IProviderCoinInfoStorage

    init(coinInfoProvider: ICoinInfoProvider, storage: ICoinInfoStorage & IProviderCoinInfoStorage) {
        self.coinInfoProvider = coinInfoProvider
        self.storage = storage

        prepareCoinInfos()
    }

    private func prepareCoinInfos() {
        if !coinInfoExists {
            coinInfoProvider.coinInfoSingle(platform: .ethereum)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onSuccess: { [weak self] coins in
                    self?.save(coins: coins)
                })
                .disposed(by: disposeBag)
        }
    }

}

extension CoinInfoManager {

    var coinInfoExists: Bool {
        storage.coinInfoCount != 0
    }

    func save(coins: [XRatesKit.Coin]) {
        let coinInfos = coins.map { coin in
            CoinInfoRecord(code: coin.code, title: coin.title, type: coin.type?.rawValue)
        }

        storage.save(coinInfos: coinInfos)
    }

    func identify(coinMarkets: [CoinMarket]) -> [CoinMarket] {
        let codes = coinMarkets.map { $0.coin.code }
        let coinInfos = storage.coinInfos(coinCodes: codes)

        return coinMarkets.map { coinMarket in
            if let coinInfo = coinInfos.first(where: { $0.code == coinMarket.coin.code }) {
                let type = coinInfo.type.flatMap {
                    XRatesKit.CoinType(rawValue: $0)
                }

                let coin = XRatesKit.Coin(code: coinInfo.code, title: coinInfo.title, type: type)
                return CoinMarket(coin: coin, marketInfo: coinMarket.marketInfo)
            }
            return coinMarket
        }
    }

}

extension CoinInfoManager {

    func save(providerCoinInfos: [ProviderCoinInfoRecord]) {
        storage.save(providerCoinInfos: providerCoinInfos)
    }

    func providerCoinInfos(providerId: Int, coinCodes: [String]) -> [ProviderCoinInfoRecord] {
        storage.providerCoinInfos(providerId: providerId, coinCodes: coinCodes)
    }

    func providerCoinInfoExist(providerId: Int) -> Bool {
        storage.providerCoinInfoCount(providerId: providerId) != 0
    }

}
