import Foundation

class NewsState {
    private static let altcoinName = "ALT_COIN"

    private let expirationTime: TimeInterval
    private var posts = [String: [CryptoNewsPost]]()
    private var lastUpdatedTimestamp = [String: TimeInterval]()

    init(expirationTime: TimeInterval) {
        self.expirationTime = expirationTime
    }

}

extension NewsState: INewsState {

    public func set(posts: [CryptoNewsPost], coinName: String) {
        let coinName = NewsManager.registeredCoinList.contains(coinName) ? coinName : NewsState.altcoinName

        self.posts[coinName] = posts.sorted()
        self.lastUpdatedTimestamp[coinName] = Date().timeIntervalSince1970
    }

    public func nonExpiredPosts(for coinName: String, timestamp: TimeInterval) -> [CryptoNewsPost]? {
        let coinName = NewsManager.registeredCoinList.contains(coinName) ? coinName : NewsState.altcoinName

        guard let posts = self.posts[coinName], let lastTimestamp = lastUpdatedTimestamp[coinName] else {
            return nil
        }
        return timestamp < (lastTimestamp + expirationTime) ? posts : nil
    }

}
