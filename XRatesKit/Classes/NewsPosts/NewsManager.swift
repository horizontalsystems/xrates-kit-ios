import RxSwift

class NewsManager {
    private let provider: INewsProvider
    private let state: INewsState

    init(provider: INewsProvider, state: INewsState) {
        self.provider = provider
        self.state = state
    }

}

extension NewsManager: INewsManager {

    func posts(timestamp: TimeInterval) -> [CryptoNewsPost]? {
        state.nonExpiredPosts(timestamp: timestamp)
    }

    func postsSingle(latestTimestamp: TimeInterval?) -> Single<[CryptoNewsPost]> {
        provider.newsSingle(latestTimestamp: latestTimestamp)
                .map { [weak self] news in
                    let posts = news.posts.map { CryptoNewsPost($0) }

                    self?.state.set(posts: posts)
                    return posts
                }
    }


}
