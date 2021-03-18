import GRDB
import RxSwift
import CoinKit

class GrdbStorage {
    private let dbPool: DatabasePool

    init() {
        let databaseURL = try! FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("XRatesKit.sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try! migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createHistoricalRates") { db in
            try db.create(table: HistoricalRate.databaseTableName) { t in
                t.column(HistoricalRate.Columns.coinId.name, .text).notNull()
                t.column(HistoricalRate.Columns.currencyCode.name, .text).notNull()
                t.column(HistoricalRate.Columns.value.name, .text).notNull()
                t.column(HistoricalRate.Columns.timestamp.name, .double).notNull()

                t.primaryKey([
                    HistoricalRate.Columns.coinId.name,
                    HistoricalRate.Columns.currencyCode.name,
                    HistoricalRate.Columns.timestamp.name,
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createChartPoints") { db in
            try db.create(table: ChartPointRecord.databaseTableName) { t in
                t.column(ChartPointRecord.Columns.coinId.name, .text).notNull()
                t.column(ChartPointRecord.Columns.currencyCode.name, .text).notNull()
                t.column(ChartPointRecord.Columns.chartType.name, .integer).notNull()
                t.column(ChartPointRecord.Columns.timestamp.name, .double).notNull()
                t.column(ChartPointRecord.Columns.value.name, .text).notNull()

                t.primaryKey([
                    ChartPointRecord.Columns.coinId.name,
                    ChartPointRecord.Columns.currencyCode.name,
                    ChartPointRecord.Columns.chartType.name,
                    ChartPointRecord.Columns.timestamp.name,
                ], onConflict: .replace)
            }
        }
        migrator.registerMigration("addVolumeToChartPoints") { db in
            try db.execute(sql: "DELETE from \(ChartPointRecord.databaseTableName)")
            try db.alter(table: ChartPointRecord.databaseTableName) { t in
                t.add(column: ChartPointRecord.Columns.volume.name, .text)
            }
        }

        migrator.registerMigration("createTopMarketCoin") { db in
            try db.create(table: TopMarketCoin.databaseTableName) { t in
                t.column(TopMarketCoin.Columns.code.name, .text).notNull()
                t.column(TopMarketCoin.Columns.title.name, .text).notNull()
                t.column(TopMarketCoin.Columns.position.name, .integer).notNull()

                t.primaryKey([
                    TopMarketCoin.Columns.code.name
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createGlobalMarketInfo") { db in
            try db.create(table: GlobalCoinMarket.databaseTableName) { t in
                t.column(GlobalCoinMarket.Columns.currencyCode.name, .text).notNull()
                t.column(GlobalCoinMarket.Columns.volume24h.name, .text).notNull()
                t.column(GlobalCoinMarket.Columns.volume24hDiff24h.name, .text).notNull()
                t.column(GlobalCoinMarket.Columns.marketCap.name, .text).notNull()
                t.column(GlobalCoinMarket.Columns.marketCapDiff24h.name, .text).notNull()
                t.column(GlobalCoinMarket.Columns.btcDominance.name, .text).notNull()
                t.column(GlobalCoinMarket.Columns.btcDominanceDiff24h.name, .text).notNull()
                t.column(GlobalCoinMarket.Columns.defiMarketCap.name, .text).notNull()
                t.column(GlobalCoinMarket.Columns.defiMarketCapDiff24h.name, .text).notNull()
                t.column(GlobalCoinMarket.Columns.defiTvl.name, .text).notNull()
                t.column(GlobalCoinMarket.Columns.defiTvlDiff24h.name, .text).notNull()

                t.primaryKey([
                    GlobalCoinMarket.Columns.currencyCode.name
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createDataVersions") { db in
            try db.create(table: DataVersion.databaseTableName) { t in
                t.column(DataVersion.Columns.id.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(DataVersion.Columns.version.name, .integer).notNull()
            }
        }

        migrator.registerMigration("createCoinExternalIds") { db in
            try db.create(table: ProviderCoinRecord.databaseTableName) { t in
                t.column(ProviderCoinRecord.Columns.id.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(ProviderCoinRecord.Columns.code.name, .text).notNull()
                t.column(ProviderCoinRecord.Columns.name.name, .text).notNull()
                t.column(ProviderCoinRecord.Columns.coingeckoId.name, .text)
                t.column(ProviderCoinRecord.Columns.cryptocompareId.name, .text)
            }
        }

        migrator.registerMigration("recreateCoinInfoRecords") { db in
            if try db.tableExists("coin_info") {
                try db.drop(table: "coin_info")
            }
            if try db.tableExists("provider_coin_info") {
                try db.drop(table: "provider_coin_info")
            }

            try db.create(table: CoinInfoRecord.databaseTableName) { t in
                t.column(CoinInfoRecord.Columns.coinId.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(CoinInfoRecord.Columns.code.name, .text).notNull()
                t.column(CoinInfoRecord.Columns.name.name, .text).notNull()
                t.column(CoinInfoRecord.Columns.rating.name, .text)
                t.column(CoinInfoRecord.Columns.description.name, .text)
            }
        }

        migrator.registerMigration("createCoinCategories") { db in
            try db.create(table: CoinCategory.databaseTableName) { t in
                t.column(CoinCategory.Columns.id.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(CoinCategory.Columns.name.name, .text).notNull()
            }
        }

        migrator.registerMigration("createCoinCategoryCoinInfos") { db in
            try db.create(table: CoinCategoryCoinInfo.databaseTableName) { t in
                t.column(CoinCategoryCoinInfo.Columns.coinCategoryId.name, .text).notNull()
                t.column(CoinCategoryCoinInfo.Columns.coinInfoId.name, .text).notNull()

                t.primaryKey([CoinCategoryCoinInfo.Columns.coinCategoryId.name, CoinCategoryCoinInfo.Columns.coinInfoId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createLinks") { db in
            try db.create(table: CoinLink.databaseTableName) { t in
                t.column(CoinLink.Columns.coinInfoId.name, .text).notNull()
                t.column(CoinLink.Columns.linkType.name, .text).notNull()
                t.column(CoinLink.Columns.value.name, .text).notNull()
                
                t.primaryKey([CoinLink.Columns.coinInfoId.name, CoinLink.Columns.linkType.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("changeChartAndHistoricalCoinId") { db in
            if try db.tableExists(ChartPointRecord.databaseTableName) {
                try db.drop(table: ChartPointRecord.databaseTableName)
            }

            try db.create(table: ChartPointRecord.databaseTableName) { t in
                t.column(ChartPointRecord.Columns.coinId.name, .text).notNull()
                t.column(ChartPointRecord.Columns.currencyCode.name, .text).notNull()
                t.column(ChartPointRecord.Columns.chartType.name, .integer).notNull()
                t.column(ChartPointRecord.Columns.timestamp.name, .double).notNull()
                t.column(ChartPointRecord.Columns.value.name, .text).notNull()
                t.column(ChartPointRecord.Columns.volume.name)

                t.primaryKey([
                    ChartPointRecord.Columns.coinId.name,
                    ChartPointRecord.Columns.currencyCode.name,
                    ChartPointRecord.Columns.chartType.name,
                    ChartPointRecord.Columns.timestamp.name,
                ], onConflict: .replace)
            }

            if try db.tableExists(HistoricalRate.databaseTableName) {
                try db.drop(table: HistoricalRate.databaseTableName)
            }

            try db.create(table: HistoricalRate.databaseTableName) { t in
                t.column(HistoricalRate.Columns.coinId.name, .text).notNull()
                t.column(HistoricalRate.Columns.currencyCode.name, .text).notNull()
                t.column(HistoricalRate.Columns.value.name, .text).notNull()
                t.column(HistoricalRate.Columns.timestamp.name, .double).notNull()

                t.primaryKey([
                    HistoricalRate.Columns.coinId.name,
                    HistoricalRate.Columns.currencyCode.name,
                    HistoricalRate.Columns.timestamp.name,
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("recreateLatestRates") { db in
            if try db.tableExists("market_info") {
                try db.drop(table: "market_info")
            }

            try db.create(table: LatestRateRecord.databaseTableName) { t in
                t.column(LatestRateRecord.Columns.coinId.name, .text).notNull()
                t.column(LatestRateRecord.Columns.currencyCode.name, .text).notNull()
                t.column(LatestRateRecord.Columns.rate.name, .text).notNull()
                t.column(LatestRateRecord.Columns.rateDiff24h.name, .text).notNull()
                t.column(LatestRateRecord.Columns.timestamp.name, .double).notNull()

                t.primaryKey([
                    LatestRateRecord.Columns.coinId.name,
                    LatestRateRecord.Columns.currencyCode.name,
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createCoinFunds") { db in
            try db.create(table: CoinFund.databaseTableName) { t in
                t.column(CoinFund.Columns.id.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(CoinFund.Columns.name.name, .text).notNull()
                t.column(CoinFund.Columns.url.name, .text).notNull()
                t.column(CoinFund.Columns.category.name, .text).notNull()
            }
        }

        migrator.registerMigration("createCoinFundCoinInfos") { db in
            try db.create(table: CoinFundCoinInfo.databaseTableName) { t in
                t.column(CoinFundCoinInfo.Columns.coinFundId.name, .text).notNull()
                t.column(CoinFundCoinInfo.Columns.coinInfoId.name, .text).notNull()

                t.primaryKey([CoinFundCoinInfo.Columns.coinFundId.name, CoinFundCoinInfo.Columns.coinInfoId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createCoinFundCategory") { db in
            try db.create(table: CoinFundCategory.databaseTableName) { t in
                t.column(CoinFundCategory.Columns.id.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(CoinFundCategory.Columns.name.name, .text).notNull()
                t.column(CoinFundCategory.Columns.order.name, .integer).notNull()
            }
        }

        return migrator
    }

}

extension GrdbStorage: ILatestRatesStorage {

    func latestRateRecord(key: PairKey) -> LatestRateRecord? {
        try! dbPool.read { db in
            try LatestRateRecord.filter(LatestRateRecord.Columns.coinId == key.coinType.id && LatestRateRecord.Columns.currencyCode == key.currencyCode).fetchOne(db)
        }
    }

    func latestRateRecordsSortedByTimestamp(coinTypes: [CoinType], currencyCode: String) -> [LatestRateRecord] {
        try! dbPool.read { db in
            try LatestRateRecord
                    .filter(coinTypes.map{ $0.id }.contains(LatestRateRecord.Columns.coinId) && LatestRateRecord.Columns.currencyCode == currencyCode)
                    .order(LatestRateRecord.Columns.timestamp)
                    .fetchAll(db)
        }
    }

    func save(marketInfoRecords: [LatestRateRecord]) {
        _ = try! dbPool.write { db in
            for rate in marketInfoRecords {
                try rate.insert(db)
            }
        }
    }

}

extension GrdbStorage: ITopMarketsStorage {

    func topMarkets(currencyCode: String, limit: Int) -> [(coin: TopMarketCoin, marketInfo: LatestRateRecord)] {
        try! dbPool.read { db -> [(coin: TopMarketCoin, marketInfo: LatestRateRecord)] in
            let marketInfoC = LatestRateRecord.Columns.allCases.count
            let coinC = TopMarketCoin.Columns.allCases.count

            let adapter = ScopeAdapter([
                "marketInfo": RangeRowAdapter(0..<marketInfoC),
                "coin": RangeRowAdapter(marketInfoC..<marketInfoC + coinC)
            ])

            let sql = """
                      SELECT market_info.*, top_market_coin.*
                      FROM market_info
                      INNER JOIN top_market_coin ON market_info.coinCode = top_market_coin.code
                      ORDER BY top_market_coin.position
                      LIMIT \(limit)
                      """

            let rows = try Row.fetchCursor(db, sql: sql, adapter: adapter)
            var topMarkets = [(coin: TopMarketCoin, marketInfo: LatestRateRecord)]()

            while let row = try rows.next() {
                topMarkets.append((coin: row["coin"], marketInfo: row["marketInfo"]))
            }

            return topMarkets
        }
    }

    func save(topMarkets: [(coin: TopMarketCoin, marketInfo: LatestRateRecord)]) {
        _ = try! dbPool.write { db in
            try TopMarketCoin.deleteAll(db)
            var position = 0

            for topMarket in topMarkets {
                topMarket.coin.position = position
                position += 1

                try topMarket.coin.insert(db)
                try topMarket.marketInfo.insert(db)
            }
        }
    }

}

extension GrdbStorage: IHistoricalRateStorage {

    func rate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> HistoricalRate? {
        try! dbPool.read { db in
            try HistoricalRate
                    .filter(HistoricalRate.Columns.coinId == coinType.id && HistoricalRate.Columns.currencyCode == currencyCode && HistoricalRate.Columns.timestamp == timestamp)
                    .fetchOne(db)
        }
    }

    func save(historicalRate: HistoricalRate) {
        _ = try! dbPool.write { db in
            try historicalRate.insert(db)
        }
    }

}

extension GrdbStorage: IChartPointStorage {

    func chartPointRecords(key: ChartInfoKey) -> [ChartPointRecord] {
        try! dbPool.read { db in
            try ChartPointRecord
                    .filter(ChartPointRecord.Columns.coinId == key.coinType.id && ChartPointRecord.Columns.currencyCode == key.currencyCode && ChartPointRecord.Columns.chartType == key.chartType.rawValue)
                    .order(ChartPointRecord.Columns.timestamp).fetchAll(db)
        }
    }

    func save(chartPointRecords: [ChartPointRecord]) {
        _ = try! dbPool.write { db in
            for record in chartPointRecords {
                try record.insert(db)
            }
        }
    }

    func deleteChartPointRecords(key: ChartInfoKey) {
        _ = try! dbPool.write { db in
            try ChartPointRecord
                    .filter(ChartPointRecord.Columns.coinId == key.coinType.id && ChartPointRecord.Columns.currencyCode == key.currencyCode && ChartPointRecord.Columns.chartType == key.chartType.rawValue)
                    .deleteAll(db)
        }
    }

}

extension GrdbStorage: IGlobalMarketInfoStorage {

    func save(globalMarketInfo: GlobalCoinMarket) {
        _ = try! dbPool.write { db in
            try globalMarketInfo.insert(db)
        }
    }

    func globalMarketInfo(currencyCode: String) -> GlobalCoinMarket? {
        try! dbPool.read { db in
            try GlobalCoinMarket
                .filter(GlobalCoinMarket.Columns.currencyCode == currencyCode)
                .fetchOne(db)
        }
    }

}

extension GrdbStorage: ICoinInfoStorage {

    var coinInfosVersion: Int {
        try! dbPool.read { db in
            try DataVersion.filter(DataVersion.Columns.id == DataVersion.DataTypes.coinInfos.rawValue).fetchOne(db)?.version ?? 0
        }
    }

    func set(coinInfosVersion: Int) {
        try! dbPool.write { db in
            try DataVersion(id: DataVersion.DataTypes.coinInfos.rawValue, version: coinInfosVersion).save(db)
        }
    }
    
    func update(coinCategories: [CoinCategory]) {
        _ = try! dbPool.write { db in
            try CoinCategory.deleteAll(db)

            for category in coinCategories {
                try category.insert(db)
            }
        }
    }

    func update(coinFunds: [CoinFund]) {
        _ = try! dbPool.write { db in
            try CoinFund.deleteAll(db)

            for fund in coinFunds {
                try fund.insert(db)
            }
        }
    }

    func update(coinFundCategories: [CoinFundCategory]) {
        _ = try! dbPool.write { db in
            try CoinFundCategory.deleteAll(db)

            for fundCategory in coinFundCategories {
                try fundCategory.insert(db)
            }
        }
    }

    func update(coinInfos: [CoinInfoRecord], categoryMaps: [CoinCategoryCoinInfo], fundMaps: [CoinFundCoinInfo], links: [CoinLink]) {
        _ = try! dbPool.write { db in
            try CoinInfoRecord.deleteAll(db)
            try CoinCategoryCoinInfo.deleteAll(db)
            try CoinFundCoinInfo.deleteAll(db)
            try CoinLink.deleteAll(db)

            for coinInfo in coinInfos {
                try coinInfo.insert(db)
            }

            for categoryMap in categoryMaps {
                try categoryMap.insert(db)
            }

            for fundMap in fundMaps {
                try fundMap.insert(db)
            }

            for link in links {
                try link.insert(db)
            }
        }
    }

    func providerCoinInfo(coinType: CoinType) -> (data: CoinData, meta: CoinMeta)? {
        try! dbPool.read { db in
            guard let record = try CoinInfoRecord.filter(CoinInfoRecord.Columns.coinId == coinType.id).fetchOne(db) else {
                return nil
            }

            let categoryIds = try CoinCategoryCoinInfo.filter(CoinCategoryCoinInfo.Columns.coinInfoId == record.coinType.id).fetchAll(db).map { $0.coinCategoryId }
            let categoryNames: [String] = try CoinCategory.filter(categoryIds.contains(CoinCategory.Columns.id)).fetchAll(db).map { $0.name }

            let fundIds = try CoinFundCoinInfo.filter(CoinFundCoinInfo.Columns.coinInfoId == record.coinType.id).fetchAll(db).map { $0.coinFundId }
            let funds: [CoinFund] = try CoinFund.filter(fundIds.contains(CoinCategory.Columns.id)).fetchAll(db)
            let fundCategoryIds = Array(Set(funds.map { $0.category }))
            let categories: [CoinFundCategory] = try CoinFundCategory.filter(fundCategoryIds.contains(CoinFundCategory.Columns.id)).order(CoinFundCategory.Columns.order.asc).fetchAll(db)

            for category in categories {
                category.funds = funds.filter { $0.category == category.id }
            }

            let links = try CoinLink.filter(CoinLink.Columns.coinInfoId == record.coinType.id).fetchAll(db)
            var linksMap = [LinkType: String]()
            for link in links {
                if let linkType = LinkType(rawValue: link.linkType) {
                    linksMap[linkType] = link.value
                }
            }

            let data = CoinData(coinType: coinType, code: record.code, name: record.name)
            let meta = CoinMeta(
                    description: record.description ?? "",
                    links: linksMap,
                    rating: record.rating,
                    categories: categoryNames,
                    fundCategories: categories,
                    platforms: [:]
            )

            return (data: data, meta: meta)
        }
    }

}

extension GrdbStorage: IProviderCoinsStorage {

    var providerCoinsVersion: Int {
        try! dbPool.read { db in
            try DataVersion.filter(DataVersion.Columns.id == DataVersion.DataTypes.providerCoins.rawValue).fetchOne(db)?.version ?? 0
        }
    }

    func set(providerCoinsVersion: Int) {
        try! dbPool.write { db in
            try DataVersion(id: DataVersion.DataTypes.providerCoins.rawValue, version: providerCoinsVersion).save(db)
        }
    }

    func update(providerCoins: [ProviderCoinRecord]) {
        _ = try! dbPool.write { db in
            try ProviderCoinRecord.deleteAll(db)

            try providerCoins.forEach { record in
                try record.insert(db)
            }
        }
    }

    func providerId(id: String, provider: InfoProvider) -> String? {
        try! dbPool.read { db in
            let record = try ProviderCoinRecord.filter(ProviderCoinRecord.Columns.id == id).fetchAll(db).first

            switch provider {
            case .CoinGecko: return record?.coingeckoId
            case .CryptoCompare: return record?.cryptocompareId
            default: return nil
            }
        }
    }

    func ids(providerId: String, provider: InfoProvider) -> [String] {
        try! dbPool.read { db in
            let filter: SQLExpressible

            switch provider {
            case .CoinGecko: filter = ProviderCoinRecord.Columns.coingeckoId == providerId
            case .CryptoCompare: filter = ProviderCoinRecord.Columns.cryptocompareId == providerId
            default: return []
            }

            return try ProviderCoinRecord
                    .filter(filter)
                    .fetchAll(db)
                    .map { $0.id }
        }
    }

    func find(text: String) -> [CoinData] {
        try! dbPool.read { db in
            try ProviderCoinRecord
                    .filter(ProviderCoinRecord.Columns.code.like("%\(text)%") || ProviderCoinRecord.Columns.name.like("%\(text)%"))
                    .fetchAll(db)
                    .map { record in
                        CoinData(coinType: CoinType(id: record.id), code: record.code, name: record.name)
                    }
        }
    }

}
