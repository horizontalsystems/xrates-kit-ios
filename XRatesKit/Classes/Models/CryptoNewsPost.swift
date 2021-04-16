public class CryptoNewsPost {
    public let id: Int
    public let timestamp: TimeInterval
    public let imageUrl: String?
    public let title: String
    public let url: String
    public let body: String
    public let categories: [String]

    init(_ response: Int) {
        self.id = response
        timestamp = 0 // response.timestamp
        imageUrl = nil // response.imageUrl
        title = "" // response.title
        url = "" // response.url
        body = "" // response.body
        categories = [] // response.categories.split(separator: "|").map { String($0) }
    }

}

extension CryptoNewsPost: CustomStringConvertible {

    public var description: String {
        "NewsPost [id: \(id); timestamp: \(timestamp); title: \(title); url: \(url)]"
    }

}

extension CryptoNewsPost: Comparable {

    static public func ==(lhs: CryptoNewsPost, rhs: CryptoNewsPost) -> Bool {
        lhs.id == rhs.id
    }

    public static func <(lhs: CryptoNewsPost, rhs: CryptoNewsPost) -> Bool {
        lhs.timestamp > rhs.timestamp
    }

}
