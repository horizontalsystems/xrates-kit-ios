import RxSwift

class NewsManager {
    private static let altcoinCategories = "Altcoin,Trading"
    static let registeredCoinList = [
        "BTC",
        "BCH",
        "ETH",
        "DASH",
        "USDT",
    ]

    private let provider: INewsProvider
    private let state: INewsState

    init(provider: INewsProvider, state: INewsState) {
        self.provider = provider
        self.state = state
    }

}

extension NewsManager: INewsManager {

    func posts(for coinName: String, timestamp: TimeInterval) -> [CryptoNewsPost]? {
        state.nonExpiredPosts(for: coinName, timestamp: timestamp)
    }

    func postsSingle(for coinName: String, latestTimestamp: TimeInterval?) -> Single<[CryptoNewsPost]> {
        let categories = NewsManager.registeredCoinList.contains(coinName) ? coinName : NewsManager.altcoinCategories

        return provider.newsSingle(for: [categories, "Regulation"].joined(separator: ","), latestTimestamp: latestTimestamp)
                .map { [weak self] news in
                    let posts = news.posts.map { CryptoNewsPost($0) }

                    self?.state.set(posts: posts, coinName: coinName)
                    return posts
                }
    }


}
