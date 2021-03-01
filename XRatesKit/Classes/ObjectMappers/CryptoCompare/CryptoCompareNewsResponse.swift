import ObjectMapper

struct CryptoCompareNewsResponse: ImmutableMappable {
    let posts: [CryptoCompareChartNewsPostResponse]

    init(map: Map) throws {
        try CryptoCompareResponse.validate(map: map)

        posts = try map.value("Data")
    }

}
