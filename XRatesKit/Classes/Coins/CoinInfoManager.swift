import Foundation
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

    private let url: String
    private let storage: ICoinInfoStorage
    private let exchangeStorage: IExchangeStorage
    private let dataProvider: CoinsDataProvider

    private static let coinsUpdateInterval: TimeInterval = 10 * 24 * 60 * 60 // 10 days

    init(storage: ICoinInfoStorage, exchangeStorage: IExchangeStorage, dataProvider: CoinsDataProvider, url: String) {
        self.storage = storage
        self.exchangeStorage = exchangeStorage
        self.dataProvider = dataProvider
        self.url = url
    }

    private func updateCoins(list: CoinsList) {
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
    }

    func coinTypes(forCategoryId categoryId: String) -> [CoinType] {
        storage.coins(forCategoryId: categoryId).map { $0.coinType }
    }

}

extension CoinInfoManager {

    func sync() -> Single<()> {
        guard Date().timeIntervalSince1970 - TimeInterval(storage.version(type: .coinInfos)) > CoinInfoManager.coinsUpdateInterval else {
            return Single.just(())
        }

        return dataProvider.parse(url: URL(string: url)!)
                .flatMap { [weak self] (list: CoinsList) -> Single<()> in
                    self?.updateCoins(list: list)
                    return Single.just(())
                }
    }

    func coinInfo(coinType: CoinType) -> (data: CoinData, meta: CoinMeta)? {
        storage.providerCoinInfo(coinType: coinType)
    }

}
