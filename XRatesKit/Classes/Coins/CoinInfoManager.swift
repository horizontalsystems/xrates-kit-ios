import RxSwift
import XRatesKit

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
            CoinInfoRecord(code: coin.code, title: coin.title, type: coin.type?.id, contractAddress: coin.type?.contractAddress)
        }

        storage.save(coinInfos: coinInfos)
    }

    func identify(coinMarkets: [CoinMarket]) -> [CoinMarket] {
        let codes = coinMarkets.map { $0.coin.code }
        var coinDictionary: [String: CoinMarket] = Dictionary(coinMarkets.map { ($0.coin.code, $0) }, uniquingKeysWith: { (first, _) in first })
        storage
            .coinInfos(coinCodes: codes)
            .forEach { coinInfo in
                let type: XRatesKit.CoinType?
                if let address = coinInfo.contractAddress {
                    type = .erc20(address: address)
                } else {
                    type = coinInfo.type.flatMap { XRatesKit.CoinType.baseType(id: $0) }
                }
                if let coinMarket = coinDictionary[coinInfo.code] {
                    let coin = XRatesKit.Coin(code: coinInfo.code, title: coinInfo.title, type: type)
                    coinDictionary[coinInfo.code] = CoinMarket(coin: coin, marketInfo: coinMarket.marketInfo)
                }
            }

        return Array(coinDictionary.values)
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
