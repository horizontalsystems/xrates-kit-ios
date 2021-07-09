import CoinKit
import RxSwift

class TokenInfoManager {
    private let provider: ITokenInfoProvider

    init(provider: ITokenInfoProvider) {
        self.provider = provider
    }

    func topTokenHoldersSingle(coinType: CoinType, itemsCount: Int) -> Single<[TokenHolder]> {
        provider.topTokenHoldersSingle(coinType: coinType, itemsCount: itemsCount)
    }

}
