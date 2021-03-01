import ObjectMapper
import CoinKit

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

    private let filename = "provider.coins"
    private let storage: IProviderCoinsStorage
    private let parser: JsonFileParser

    init(storage: IProviderCoinsStorage, parser: JsonFileParser) {
        self.storage = storage
        self.parser = parser

        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.updateIds()
        }
    }

    private func updateIds() {
        do {
            let list: ProviderCoinsList = try parser.parse(filename: filename)

            guard list.version > storage.providerCoinsVersion else {
                return
            }

            let coinRecords = list.coins.map { coin in
                ProviderCoinRecord(id: coin.id, code: coin.code, name: coin.name, coingeckoId: coin.externalId.coingecko, cryptocompareId: coin.externalId.cryptocompare)
            }

            storage.update(providerCoins: coinRecords)
            storage.set(providerCoinsVersion: list.version)
        } catch {
            print(error.localizedDescription)
        }
    }

}

extension ProviderCoinsManager {

    func providerId(coinType: CoinType, provider: InfoProvider) -> String? {
        storage.providerId(id: coinType.id, provider: provider)
    }

    func coinType(providerId: String, provider: InfoProvider) -> CoinType? {
        storage.id(providerId: providerId, provider: provider).flatMap { CoinType(id: $0) }
    }

    func search(text: String) -> [CoinData] {
        guard !text.isEmpty else {
            return []
        }

        return storage.find(text: text)
    }

}
