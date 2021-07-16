import CoinKit
import RxSwift

class TokenInfoManager {
    private let tokenInfoProvider: ITokenInfoProvider
    private let auditInfoProvider: IAuditInfoProvider

    init(tokenInfoProvider: ITokenInfoProvider, auditInfoProvider: IAuditInfoProvider) {
        self.tokenInfoProvider = tokenInfoProvider
        self.auditInfoProvider = auditInfoProvider
    }

    func topTokenHoldersSingle(coinType: CoinType, itemsCount: Int) -> Single<[TokenHolder]> {
        tokenInfoProvider.topTokenHoldersSingle(coinType: coinType, itemsCount: itemsCount)
    }

    func auditReportsSingle(coinType: CoinType) -> Single<[Auditor]> {
        auditInfoProvider.auditReportsSingle(coinType: coinType)
    }

}
