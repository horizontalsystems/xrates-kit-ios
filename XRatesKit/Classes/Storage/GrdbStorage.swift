import GRDB
import RxSwift

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

        migrator.registerMigration("createMarketInfo") { db in
            try db.create(table: MarketInfoRecord.databaseTableName) { t in
                t.column(MarketInfoRecord.Columns.coinCode.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.currencyCode.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.timestamp.name, .double).notNull()
                t.column(MarketInfoRecord.Columns.rate.name, .text).notNull()
                t.column("open24Hour", .text).notNull()
                t.column(MarketInfoRecord.Columns.diff.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.volume.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.marketCap.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.supply.name, .text).notNull()

                t.primaryKey([
                    MarketInfoRecord.Columns.coinCode.name,
                    MarketInfoRecord.Columns.currencyCode.name,
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createHistoricalRates") { db in
            try db.create(table: HistoricalRate.databaseTableName) { t in
                t.column(HistoricalRate.Columns.coinCode.name, .text).notNull()
                t.column(HistoricalRate.Columns.currencyCode.name, .text).notNull()
                t.column(HistoricalRate.Columns.value.name, .text).notNull()
                t.column(HistoricalRate.Columns.timestamp.name, .double).notNull()

                t.primaryKey([
                    HistoricalRate.Columns.coinCode.name,
                    HistoricalRate.Columns.currencyCode.name,
                    HistoricalRate.Columns.timestamp.name,
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createChartPoints") { db in
            try db.create(table: ChartPointRecord.databaseTableName) { t in
                t.column(ChartPointRecord.Columns.coinCode.name, .text).notNull()
                t.column(ChartPointRecord.Columns.currencyCode.name, .text).notNull()
                t.column(ChartPointRecord.Columns.chartType.name, .integer).notNull()
                t.column(ChartPointRecord.Columns.timestamp.name, .double).notNull()
                t.column(ChartPointRecord.Columns.value.name, .text).notNull()

                t.primaryKey([
                    ChartPointRecord.Columns.coinCode.name,
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

        migrator.registerMigration("addMarketInfoOpenDay") { db in
            try db.drop(table: MarketInfoRecord.databaseTableName)

            try db.create(table: MarketInfoRecord.databaseTableName) { t in
                t.column(MarketInfoRecord.Columns.coinCode.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.currencyCode.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.timestamp.name, .double).notNull()
                t.column(MarketInfoRecord.Columns.rate.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.openDay.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.diff.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.volume.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.marketCap.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.supply.name, .text).notNull()

                t.primaryKey([
                    MarketInfoRecord.Columns.coinCode.name,
                    MarketInfoRecord.Columns.currencyCode.name,
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

        migrator.registerMigration("addMarketInfoLiquidityAndDiffPeriod") { db in
            try db.drop(table: MarketInfoRecord.databaseTableName)

            try db.create(table: MarketInfoRecord.databaseTableName) { t in
                t.column(MarketInfoRecord.Columns.coinCode.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.currencyCode.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.timestamp.name, .double).notNull()
                t.column(MarketInfoRecord.Columns.rate.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.openDay.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.diff.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.volume.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.marketCap.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.supply.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.liquidity.name, .text).notNull()
                t.column(MarketInfoRecord.Columns.rateDiffPeriod.name, .text).notNull()

                t.primaryKey([
                    MarketInfoRecord.Columns.coinCode.name,
                    MarketInfoRecord.Columns.currencyCode.name,
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createCoinInfo") { db in
            try db.create(table: CoinInfoRecord.databaseTableName) { t in
                t.column(CoinInfoRecord.Columns.code.name, .text).notNull()
                t.column(CoinInfoRecord.Columns.title.name, .text).notNull()
                t.column(CoinInfoRecord.Columns.type.name, .text)

                t.primaryKey([
                    CoinInfoRecord.Columns.code.name,
                    CoinInfoRecord.Columns.title.name,
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createProviderCoinInfo") { db in
            try db.create(table: ProviderCoinInfoRecord.databaseTableName) { t in
                t.column(ProviderCoinInfoRecord.Columns.code.name, .text).notNull()
                t.column(ProviderCoinInfoRecord.Columns.providerId.name, .integer).notNull()
                t.column(ProviderCoinInfoRecord.Columns.providerCoinId.name, .text).notNull()

                t.primaryKey([
                    ProviderCoinInfoRecord.Columns.providerId.name,
                    ProviderCoinInfoRecord.Columns.code.name,
                ], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension GrdbStorage: IMarketInfoStorage {

    func marketInfoRecord(key: PairKey) -> MarketInfoRecord? {
        try! dbPool.read { db in
            try MarketInfoRecord.filter(MarketInfoRecord.Columns.coinCode == key.coinCode && MarketInfoRecord.Columns.currencyCode == key.currencyCode).fetchOne(db)
        }
    }

    func marketInfoRecordsSortedByTimestamp(coinCodes: [String], currencyCode: String) -> [MarketInfoRecord] {
        try! dbPool.read { db in
            try MarketInfoRecord
                    .filter(coinCodes.contains(MarketInfoRecord.Columns.coinCode) && MarketInfoRecord.Columns.currencyCode == currencyCode)
                    .order(MarketInfoRecord.Columns.timestamp)
                    .fetchAll(db)
        }
    }

    func save(marketInfoRecords: [MarketInfoRecord]) {
        _ = try! dbPool.write { db in
            for rate in marketInfoRecords {
                try rate.insert(db)
            }
        }
    }

}

extension GrdbStorage: ITopMarketsStorage {

    func topMarkets(currencyCode: String, limit: Int) -> [(coin: TopMarketCoin, marketInfo: MarketInfoRecord)] {
        try! dbPool.read { db -> [(coin: TopMarketCoin, marketInfo: MarketInfoRecord)] in
            let marketInfoC = MarketInfoRecord.Columns.allCases.count
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
            var topMarkets = [(coin: TopMarketCoin, marketInfo: MarketInfoRecord)]()

            while let row = try rows.next() {
                topMarkets.append((coin: row["coin"], marketInfo: row["marketInfo"]))
            }

            return topMarkets
        }
    }

    func save(topMarkets: [(coin: TopMarketCoin, marketInfo: MarketInfoRecord)]) {
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

    func rate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> HistoricalRate? {
        try! dbPool.read { db in
            try HistoricalRate
                    .filter(HistoricalRate.Columns.coinCode == coinCode && HistoricalRate.Columns.currencyCode == currencyCode && HistoricalRate.Columns.timestamp == timestamp)
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
                    .filter(ChartPointRecord.Columns.coinCode == key.coinCode && ChartPointRecord.Columns.currencyCode == key.currencyCode && ChartPointRecord.Columns.chartType == key.chartType.rawValue)
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
                    .filter(ChartPointRecord.Columns.coinCode == key.coinCode && ChartPointRecord.Columns.currencyCode == key.currencyCode && ChartPointRecord.Columns.chartType == key.chartType.rawValue)
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

    func save(coinInfos: [CoinInfoRecord]) {
        _ = try! dbPool.write { db in
            for coinInfo in coinInfos {
                try coinInfo.insert(db)
            }
        }

    }

    func coinInfos(coinCodes: [String]) -> [CoinInfoRecord] {
        try! dbPool.read { db in
            try CoinInfoRecord
                    .filter(coinCodes.contains(CoinInfoRecord.Columns.code))
                    .fetchAll(db)
        }
    }

    var coinInfoCount: Int {
        try! dbPool.read { db in
            try CoinInfoRecord.fetchCount(db)
        }
    }

}

extension GrdbStorage: IProviderCoinInfoStorage {

    func providerCoinInfoCount(providerId: Int) -> Int {
        try! dbPool.read { db in
            try ProviderCoinInfoRecord
                    .filter(ProviderCoinInfoRecord.Columns.providerId == providerId)
                    .fetchCount(db)
        }
    }

    func save(providerCoinInfos: [ProviderCoinInfoRecord]) {
        _ = try! dbPool.write { db in
            for providerCoinInfo in providerCoinInfos {
                try providerCoinInfo.insert(db)
            }
        }
    }

    func providerCoinInfos(providerId: Int, coinCodes: [String]) -> [ProviderCoinInfoRecord] {
        try! dbPool.read { db in
            try ProviderCoinInfoRecord
                .filter(ProviderCoinInfoRecord.Columns.providerId == providerId && coinCodes.contains(CoinInfoRecord.Columns.code))
                .fetchAll(db)
        }
    }

}
