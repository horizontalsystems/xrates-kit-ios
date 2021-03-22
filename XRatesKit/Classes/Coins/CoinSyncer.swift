import RxSwift
import CoinKit

class CoinSyncer {
    private let disposeBag = DisposeBag()

    private let providerCoinsManager: ProviderCoinsManager
    private let coinInfoManager: CoinInfoManager

    init(providerCoinsManager: ProviderCoinsManager, coinInfoManager: CoinInfoManager) {
        self.providerCoinsManager = providerCoinsManager
        self.coinInfoManager = coinInfoManager

        sync()
    }

    private func sync() {
        coinInfoManager
                .sync()
                .flatMap { [weak self] _ -> Single<Void> in
                    self?.providerCoinsManager.sync() ?? Single.just(())
                }
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] _ in
                    self?.providerCoinsManager.updatePriorities()
                })
                .disposed(by: disposeBag)
    }

}
