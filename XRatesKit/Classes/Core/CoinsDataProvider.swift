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

    func parse<T: Decodable>(filename: String) -> Single<T> {
        Single<T>.create { observer in
            guard let bundle = (Bundle(for: XRatesKit.self).url(forResource: "XRatesKit", withExtension: "bundle").flatMap { Bundle(url: $0) }), let path = bundle.path(forResource: filename, ofType: "json") else {
                observer(.error(ParseError.notFound))
                return Disposables.create()
            }

            do {
                let text = try String(contentsOfFile: path, encoding: .utf8)
                if let textData = text.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase

                    let object: T = try decoder.decode(T.self, from: textData)

                    observer(.success(object))
                } else {
                    observer(.error(ParseError.cantParse))
                }
            } catch {
                observer(.error(error))
            }
            return Disposables.create()
        }
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
