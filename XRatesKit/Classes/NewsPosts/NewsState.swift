import Foundation

class NewsState {
    private let expirationTime: TimeInterval
    private var posts = [CryptoNewsPost]()
    private var lastUpdatedTimestamp: TimeInterval?

    init(expirationTime: TimeInterval) {
        self.expirationTime = expirationTime
    }

}

extension NewsState: INewsState {

    public func set(posts: [CryptoNewsPost]) {
        self.posts = posts.sorted()
        self.lastUpdatedTimestamp = Date().timeIntervalSince1970
    }

    public func nonExpiredPosts(timestamp: TimeInterval) -> [CryptoNewsPost]? {
        guard !self.posts.isEmpty, let lastTimestamp = lastUpdatedTimestamp else {
            return nil
        }
        return timestamp < (lastTimestamp + expirationTime) ? posts : nil
    }

}
