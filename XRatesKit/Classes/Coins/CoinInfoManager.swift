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
    let security: CoinSecurityInfo?
}

fileprivate struct CoinSecurityInfo: Decodable {
    let privacy: String
    let decentralized: Bool
    let confiscationResistance: Bool
    let censorshipResistance: Bool
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
    private let filename = "coins"
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
        var securities = [CoinSecurity]()

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

            if let security = coin.security, let privacy = SecurityLevel(rawValue: security.privacy) {
                let coinSecurity = CoinSecurity(
                        coinId: coin.id,
                        privacy: privacy,
                        decentralized: security.decentralized,
                        confiscationResistance: security.confiscationResistance,
                        censorshipResistance: security.censorshipResistance
                )
                securities.append(coinSecurity)
            }
        }

        storage.update(coinCategories: list.categories)
        storage.update(coinFunds: list.funds)
        storage.update(coinFundCategories: list.fundCategories)
        exchangeStorage.update(exchanges: list.exchanges)
        storage.update(coinInfos: coinInfos, categoryMaps: coinCategoryCoinInfos, fundMaps: coinFundCoinInfos, links: links, securities: securities)
        storage.set(coinInfosVersion: list.version)
    }

    func coinTypes(forCategoryId categoryId: String) -> [CoinType] {
        storage.coins(forCategoryId: categoryId).map { $0.coinType }
    }

}

extension CoinInfoManager {

    func sync() -> Single<()> {
        let version = storage.version(type: .coinInfos)

        let remoteSingle: Single<CoinsList> = dataProvider.parse(url: URL(string: url)!)
        return dataProvider.parse(filename: filename)
                .flatMap { [weak self] (list: CoinsList) -> Single<CoinsList> in
                    guard Date().timeIntervalSince1970 - TimeInterval(version) > CoinInfoManager.coinsUpdateInterval else {
                        return Single.just(list)
                    }

                    self?.updateCoins(list: list)

                    return remoteSingle
                }
                .flatMap { [weak self] (list: CoinsList) -> Single<()> in
                    self?.updateCoins(list: list)
                    return Single.just(())
                }
    }

    func coinInfo(coinType: CoinType) -> (data: CoinData, meta: CoinMeta)? {
        storage.providerCoinInfo(coinType: coinType)
    }

}
