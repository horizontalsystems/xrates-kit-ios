import RxSwift
import HsToolKit
import Alamofire
import CoinKit

class CryptoCompareProvider {

    let provider = InfoProvider.cryptoCompare

    private let networkManager: NetworkManager
    private let apiKey: String?

    init(networkManager: NetworkManager, apiKey: String?) {
        self.networkManager = networkManager
        self.apiKey = apiKey
    }

    private func urlAndParams(path: String, parameters: Parameters) -> (String, Parameters) {
        var params = parameters
        if let apiKey = apiKey {
            params["apiKey"] = apiKey
        }

        return (provider.baseUrl + path, params)
    }

}

extension CryptoCompareProvider: INewsProvider {

    func newsSingle(latestTimestamp: TimeInterval?) -> Single<CryptoCompareNewsResponse> {
        var newsParams: Parameters = [
            "excludeCategories": "Sponsored",
            "feeds": "cointelegraph,theblock,decrypt",
            "extraParams": "Blocksdecoded"
        ]
        if let timestamp = latestTimestamp {
            newsParams["lTs"] = Int(timestamp)
        }
        let (url, parameters) = urlAndParams(path: "/data/v2/news/", parameters: newsParams)

        let request = networkManager.session
                .request(url, method: .get, parameters: parameters, interceptor: RateLimitRetrier())
                .cacheResponse(using: ResponseCacher(behavior: .doNotCache))

        return networkManager.single(request: request)
    }

}

extension CryptoCompareProvider {

    class RateLimitRetrier: RequestInterceptor {
        private var attempt = 0

        func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> ()) {
            let error = NetworkManager.unwrap(error: error)

            if case RequestError.rateLimitExceeded = error {
                completion(resolveResult())
            } else {
                completion(.doNotRetry)
            }
        }

        private func resolveResult() -> RetryResult {
            attempt += 1

            if attempt == 1 { return .retryWithDelay(3) }
            if attempt == 2 { return .retryWithDelay(6) }

            return .doNotRetry
        }

    }

}

extension CryptoCompareProvider {

    enum RequestError: Error {
        case rateLimitExceeded
        case noDataForSymbol
    }

}
