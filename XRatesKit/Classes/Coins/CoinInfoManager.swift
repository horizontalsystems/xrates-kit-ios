import ObjectMapper
import CoinKit

fileprivate struct CoinsList: Decodable {
    let version: Int
    let categories: [CoinCategory]
    let coins: [CoinsCoinInfo]
}

fileprivate struct CoinsCoinInfo: Decodable {
    let id: String
    let code: String
    let name: String
    let categories: [String]
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
    private let parser: JsonFileParser

    init(storage: ICoinInfoStorage, parser: JsonFileParser) {
        self.storage = storage
        self.parser = parser

        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.updateIds()
        }
    }

    private func updateIds() {
        do {
            let list: CoinsList = try parser.parse(filename: filename)

            guard list.version > storage.coinInfosVersion else {
                return
            }

            var coinInfos = [CoinInfoRecord]()
            var coinCategoryCoinInfos = [CoinCategoryCoinInfo]()
            var links = [CoinLink]()

            for coin in list.coins {
                coinInfos.append(CoinInfoRecord(coinType: CoinType(id: coin.id), code: coin.code, name: coin.name, rating: coin.rating, description: coin.description))

                for categoryId in coin.categories {
                    coinCategoryCoinInfos.append(CoinCategoryCoinInfo(coinCategoryId: categoryId, coinInfoId: coin.id))
                }

                for (linkType, linkValue) in coin.links.links {
                    links.append(CoinLink(coinInfoId: coin.id, linkType: linkType.rawValue, value: linkValue))
                }
            }

            storage.update(coinCategories: list.categories)
            storage.update(coinInfos: coinInfos, categoryMaps: coinCategoryCoinInfos, links: links)
            storage.set(coinInfosVersion: list.version)
        } catch {
            print(error.localizedDescription)
        }
    }

}

extension CoinInfoManager {

    func coinInfo(coinType: CoinType) -> CoinInfo? {
        storage.providerCoinInfo(coinType: coinType)
    }

}
