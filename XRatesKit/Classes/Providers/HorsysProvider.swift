import RxSwift
import HsToolKit
import Alamofire

fileprivate class HorsysDefiMarketCapMapper: IApiMapper {

    func map(statusCode: Int, data: Any?) throws -> GlobalCoinMarket {
        guard let dictionary = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        let defiMarketCap = Decimal(convertibleValue: dictionary["marketCap"]) ?? 0
        let defiMarketCapDiff24h = Decimal(convertibleValue: dictionary["marketCapDiff24h"]) ?? 0
        let defiTvl = Decimal(convertibleValue: dictionary["totalValueLocked"]) ?? 0
        let defiTvlDiff24h = Decimal(convertibleValue: dictionary["totalValueLockedDiff24h"]) ?? 0

        return GlobalCoinMarket(
                currencyCode: "",
                volume24h: 0,
                volume24hDiff24h: 0,
                marketCap: 0,
                marketCapDiff24h: 0,
                btcDominance: 0,
                btcDominanceDiff24h: 0,
                defiMarketCap: defiMarketCap,
                defiMarketCapDiff24h: defiMarketCapDiff24h,
                defiTvl: defiTvl,
                defiTvlDiff24h: defiTvlDiff24h
        )
    }

}


class HorsysProvider {

    let networkManager: NetworkManager
    private let provider = InfoProvider.Horsys

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

}

extension HorsysProvider {

    func globalDefiMarketCap(currencyCode: String) -> Single<GlobalCoinMarket> {
        let url = "\(provider.baseUrl)/markets/global/defi"
        let request = networkManager.session.request(url, method: .get, encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: HorsysDefiMarketCapMapper())
    }

}