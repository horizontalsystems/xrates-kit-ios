import Foundation

class GraphQueryBuilder {

    private static func blockNumberFilter(blockHeight: Int? = nil) -> String? {
        guard let blockHeight = blockHeight else {
            return nil
        }
        return "block:{number:\(blockHeight)}"
    }

    private static func bundlesQuery(blockHeight: Int? = nil) -> String {
        let filter = blockNumberFilter(blockHeight: blockHeight).map { "(\($0))" } ?? ""
        return "bundles\(filter) { ethPriceUSD: ethPrice }".trimmingCharacters(in: .whitespaces)
    }

    private static func tokensQuery(itemsCount: Int, blockHeight: Int? = nil) -> String {
        """
           tokens(
           first:\(itemsCount),
           orderBy:tradeVolumeUSD, 
           orderDirection:desc,
           where:{
                totalLiquidity_not:0,
                tradeVolumeUSD_gt:5000,
                derivedETH_not:0,
                symbol_not:""
           }
           \(blockNumberFilter(blockHeight: blockHeight).map { ",\($0)" } ?? ""))
           {  id,
              symbol,
              name,
              derivedETH,
              tradeVolumeUSD,
              totalLiquidity
           }
        """.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func tokensQuery(addresses: [String], blockHeight: Int? = nil) -> String {
        let joined = "\""
            + addresses
                .joined(separator: "\", \"")
                .lowercased()
            + "\""

        return """
               tokens(
                       first:\(addresses.count), 
                       where:{id_in:[\(joined)]}
                       \(blockNumberFilter(blockHeight: blockHeight).map { ",\($0)"} ?? ""))
                       {  id,
                          symbol,
                          name,
                          derivedETH,
                          tradeVolumeUSD,
                          totalLiquidity
                       }
               """.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func tokenDayDatas(addresses: [String], timestamp: Int) -> String {
        "{" + addresses.enumerated().reduce(into: "") { (result: inout String, tuple: (offset: Int, element: String)) in
            result += """
                      o\(tuple.offset):tokenDayDatas(
                      first:1,
                      orderBy:date,
                      orderDirection:desc,                       
                      where :{  
                          date_lte:\(timestamp),
                          token: "\(tuple.element)"})
                          { 
                             token { symbol, derivedETH },
                             priceUSD
                          }
                      """.trimmingCharacters(in: .whitespacesAndNewlines)
        } + "}"
    }


}

extension GraphQueryBuilder {

    static var ethPrice: String {
        bundlesQuery()
    }

    static func topTokens(itemCount: Int, blockHeight: Int? = nil) -> String {
        "\(bundlesQuery(blockHeight: blockHeight)), \(tokensQuery(itemsCount: itemCount, blockHeight: blockHeight))"
    }

    static func coinMarkets(tokenAddresses: [String], blockHeight: Int? = nil) -> String {
        "\(bundlesQuery(blockHeight: blockHeight)), \(tokensQuery(addresses: tokenAddresses, blockHeight: blockHeight))"
    }

    static func historicalXRates(tokenAddresses: [String], timestamp: Int) -> String {
        tokenDayDatas(addresses: tokenAddresses, timestamp: timestamp)
    }

}
