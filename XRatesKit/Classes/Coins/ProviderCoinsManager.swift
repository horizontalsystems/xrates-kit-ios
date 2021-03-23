import ObjectMapper
import CoinKit
import RxSwift

fileprivate struct ProviderCoinsList: Decodable {
    let version: Int
    let coins: [ProviderCoin]
}

fileprivate struct ProviderCoin: Decodable {
    let id: String
    let code: String
    let name: String
    let externalId: ExternalIds
}

fileprivate struct ExternalIds: Decodable {
    let coingecko: String?
    let cryptocompare: String?
}

class ProviderCoinsManager {
    enum ExternalIdError: Error {
        case noMatchingCoinId
    }

    private static let priorityUpdateInterval: TimeInterval = 10 * 24 * 60 * 60 // 10 days

    private let disposeBag = DisposeBag()

    private let filename = "provider.coins"
    private let storage: IProviderCoinsStorage & ICoinInfoStorage
    private let parser: JsonFileParser
    private let categorizedCoinOrder = 0

    weak var provider: CoinGeckoProvider?

    init(storage: IProviderCoinsStorage & ICoinInfoStorage, parser: JsonFileParser) {
        self.storage = storage
        self.parser = parser
    }

    private func updateIds() {
        do {
            let list: ProviderCoinsList = try parser.parse(filename: filename)

            guard list.version > storage.version(type: .providerCoins) else {
                return
            }

            let coinRecords = list.coins.map { coin in
                ProviderCoinRecord(id: coin.id, code: coin.code.uppercased(), name: coin.name, coingeckoId: coin.externalId.coingecko, cryptocompareId: coin.externalId.cryptocompare)
            }

            storage.update(providerCoins: coinRecords)
            storage.set(version: list.version, toType: .providerCoins)
        } catch {
            print(error.localizedDescription)
        }
    }

    private func updatePriorities(topCoins: [CoinMarket]) {
        var priorityCoins = [CoinType: Int]()

        for coinType in storage.categorizedCoins {
            priorityCoins[coinType] = categorizedCoinOrder
        }

        for (index, coin) in topCoins.enumerated() {
            guard priorityCoins[coin.coinData.coinType] == nil else {
                continue
            }

            priorityCoins[coin.coinData.coinType] = index + 1
        }

        storage.clearPriorities()
        for (coinType, priority) in priorityCoins {
            storage.set(priority: priority, forCoin: coinType)
        }

        storage.set(version: Int(Date().timeIntervalSince1970), toType: .providerCoinsPriority)
    }

}

extension ProviderCoinsManager {

    func sync() -> Single<Void> {
        Single<Void>.create { [weak self] observer in
            self?.updateIds()
            observer(.success(()))

            return Disposables.create()
        }
    }

    func updatePriorities() {
        guard Date().timeIntervalSince1970 - TimeInterval(storage.version(type: .providerCoinsPriority)) > ProviderCoinsManager.priorityUpdateInterval else {
            return
        }

        provider?.topCoinMarketsSingle(currencyCode: "USD", fetchDiffPeriod: .hour24, itemCount: 400)
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] topCoins in
                    self?.updatePriorities(topCoins: topCoins)
                })
                .disposed(by: disposeBag)
    }

}

extension ProviderCoinsManager {

    func providerData(coinTypes: [CoinType], provider: InfoProvider) -> [CoinType: ProviderCoinData] {
        var map = [CoinType: ProviderCoinData]()
        for coinType in coinTypes {
            if let coinData = providerData(coinType: coinType, provider: provider) {
                map[coinType] = coinData
            }
        }

        return map
    }

    func providerData(coinType: CoinType, provider: InfoProvider) -> ProviderCoinData? {
        storage.providerData(id: coinType.id, provider: provider)
    }

    func providerId(coinType: CoinType, provider: InfoProvider) -> String? {
        storage.providerId(id: coinType.id, provider: provider)
    }

    func coinTypes(providerId: String, provider: InfoProvider) -> [CoinType] {
        storage.ids(providerId: providerId, provider: provider).map { CoinType(id: $0) }
    }

    func search(text: String) -> [CoinData] {
        guard !text.isEmpty else {
            return []
        }

        return storage.find(text: text)
    }

}
