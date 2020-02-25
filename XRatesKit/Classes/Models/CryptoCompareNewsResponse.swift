import ObjectMapper

struct CryptoCompareNewsResponse: ImmutableMappable {
    let posts: [CryptoCompareChartNewsPostResponse]

    init(map: Map) throws {
        posts = try map.value("Data")
    }

}
