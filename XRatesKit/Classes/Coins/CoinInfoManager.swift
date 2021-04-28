import ObjectMapper
import CoinKit
import RxSwift

fileprivate struct CoinsList: Decodable {
    let version: Int
    let categories: [CoinCategory]
    let funds: [CoinFund]
    let fundCategories: [CoinFundCategory]
    let exchanges: [Exchange]
    let coins: [CoinsCoinInfo]
}

fileprivate struct CoinsCoinInfo: Decodable {
    let id: String
    let code: String
    let name: String
    let categories: [String]
    let funds: [String]
    let active: Bool
    let description: String?
    let rating: String?
    let links: CoinLinks
}

fileprivate struct CoinLinks: Decodable {
    let links: [LinkType: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: LinkType.self)
        var links = [LinkType: String]()

        container.allKeys.forEach { key in
            if let linkType = LinkType(rawValue: key.stringValue),
               let linkValue = try? container.decode(String.self, forKey: key), !linkValue.isEmpty {
                links[linkType] = linkValue
            }
        }

        self.links = links
    }
}

class CoinInfoManager {

    private let filename = "coins"
    private let storage: ICoinInfoStorage
    private let exchangeStorage: IExchangeStorage
    private let parser: JsonFileParser

    init(storage: ICoinInfoStorage, exchangeStorage: IExchangeStorage, parser: JsonFileParser) {
        self.storage = storage
        self.exchangeStorage = exchangeStorage
        self.parser = parser
    }

    private func updateCoins() {
        do {
            let list: CoinsList = try parser.parse(filename: filename)

            guard list.version > storage.coinInfosVersion else {
                return
            }

            var coinInfos = [CoinInfoRecord]()
            var coinCategoryCoinInfos = [CoinCategoryCoinInfo]()
            var coinFundCoinInfos = [CoinFundCoinInfo]()
            var links = [CoinLink]()

            for coin in list.coins {
                coinInfos.append(CoinInfoRecord(coinType: CoinType(id: coin.id), code: coin.code, name: coin.name, rating: coin.rating, description: coin.description))

                for categoryId in coin.categories {
                    coinCategoryCoinInfos.append(CoinCategoryCoinInfo(coinCategoryId: categoryId, coinInfoId: coin.id))
                }

                for fundId in coin.funds {
                    coinFundCoinInfos.append(CoinFundCoinInfo(coinFundId: fundId, coinInfoId: coin.id))
                }

                for (linkType, linkValue) in coin.links.links {
                    links.append(CoinLink(coinInfoId: coin.id, linkType: linkType.rawValue, value: linkValue))
                }
            }

            storage.update(coinCategories: list.categories)
            storage.update(coinFunds: list.funds)
            storage.update(coinFundCategories: list.fundCategories)
            exchangeStorage.update(exchanges: list.exchanges)
            storage.update(coinInfos: coinInfos, categoryMaps: coinCategoryCoinInfos, fundMaps: coinFundCoinInfos, links: links)
            storage.set(coinInfosVersion: list.version)
        } catch {
            print(error.localizedDescription)
        }
    }

    func coinTypes(forCategoryId categoryId: String) -> [CoinType] {
        storage.coins(forCategoryId: categoryId).map { $0.coinType }
    }

}

extension CoinInfoManager {

    func sync() -> Single<Void> {
        Single<Void>.create { [weak self] observer in
            self?.updateCoins()
            observer(.success(()))

            return Disposables.create()
        }
    }

    func coinInfo(coinType: CoinType) -> (data: CoinData, meta: CoinMeta)? {
        storage.providerCoinInfo(coinType: coinType)
    }

}
