import Foundation
import HsToolKit
import RxSwift
import ObjectMapper
import Alamofire

fileprivate class EthBlockHeightMapper: IApiMapper {
    typealias T = [TimePeriod: Int]

    func map(statusCode: Int, data: Any?) throws -> T {
        guard let dictionary = data as? [String: Any],
              let blockDictionary = dictionary["data"] as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        var result = [TimePeriod: Int]()
        blockDictionary.forEach { (key: String, value: Any) in
            if let period = TimePeriod(rawValue: key),
               let valueDictionary = (value as? [[String: Any]])?.first,
               let blockHeightString = valueDictionary["number"] as? String,
               let blockHeight = Int(blockHeightString) {

                result[period] = blockHeight
            }
        }

        return result
    }

}

class EthBlocksGraphProvider {
    private let networkManager: NetworkManager
    private let baseUrl = "https://api.thegraph.com/subgraphs/name/blocklytics/ethereum-blocks"

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    private func blockQuery(tag: String, timestamp: TimeInterval) -> String {
        let lowerRange = timestamp - 60
        return """
               \(tag):blocks(
               first: 1,
               where:{timestamp_lte:\(Int(timestamp)),timestamp_gte:\(Int(lowerRange))})
               {
                number
               }
               """.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func blockNumberQuery(data: [TimePeriod: TimeInterval]) -> String {
        data.map { "\(blockQuery(tag: $0.key.rawValue, timestamp: $0.value))" }.joined(separator: ",")
    }

    func blockHeight(data: [TimePeriod: TimeInterval]) -> Single<[TimePeriod: Int]> {
        let request = networkManager.session.request(baseUrl, method: .post, parameters: ["query": "{\(blockNumberQuery(data: data))}"], encoding: JSONEncoding())

        return networkManager.single(request: request, mapper: EthBlockHeightMapper())
    }

}
