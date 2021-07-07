import Foundation
import ObjectMapper
import HsToolKit
import Alamofire
import RxSwift

class CoinsDataProvider {

    let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func parse<T: Decodable>(url: URL) -> Single<T> {
        let request = networkManager.session.request(url, method: .get)

        return networkManager.single(request: request, mapper: SuccessMapper())
                .flatMap { dictionary in
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        return Single.just(try decoder.decode(T.self, from: jsonData))
                    } catch {
                        return Single.error(error)
                    }
                }
    }

}

extension CoinsDataProvider {

    enum ParseError: Error {
        case notFound
        case cantParse
    }

}

extension CoinsDataProvider {

    class SuccessMapper: IApiMapper {

        public func map(statusCode: Int, data: Any?) throws -> [String: Any] {
            if statusCode > 400 {
                throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
            }

            guard let map = data as? [String: Any] else {
                throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
            }

            return map
        }

    }

}
