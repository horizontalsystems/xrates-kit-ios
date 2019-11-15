import ObjectMapper

class CryptoCompareResponse {
//    let data: [String: Any]

    static func parseData(map: Map) throws -> [String: Any] {
        let type = try map.value("Type") as Int

        // rate limit exceeded
        if type == 99 {
            throw CryptoCompareError.rateLimitExceeded
        }

        // no data for requested symbol
        if type == 2 {
            throw CryptoCompareError.noDataForSymbol
        }

        guard type == 100 else {
            throw CryptoCompareError.unknownType
        }

        return try map.value("Data")
    }

}

enum CryptoCompareError: Error {
    case rateLimitExceeded
    case noDataForSymbol
    case unknownType
    case invalidData
}
