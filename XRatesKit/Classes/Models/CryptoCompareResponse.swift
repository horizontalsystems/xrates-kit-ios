import ObjectMapper

class CryptoCompareResponse {

    static func validate(map: Map) throws {
        guard let type = try? map.value("Type") as Int else {
            return
        }

        // rate limit exceeded
        if type == 99 {
            throw CryptoCompareError.rateLimitExceeded
        }

        // no data for requested symbol
        if type == 2 {
            throw CryptoCompareError.noDataForSymbol
        }
    }

}

enum CryptoCompareError: Error {
    case rateLimitExceeded
    case noDataForSymbol
    case unknownType
    case invalidData
}
