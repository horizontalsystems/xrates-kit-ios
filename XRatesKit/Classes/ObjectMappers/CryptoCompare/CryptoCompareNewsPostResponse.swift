import ObjectMapper
import HsToolKit

struct CryptoCompareChartNewsPostResponse: ImmutableMappable {
    let id: Int
    let timestamp: TimeInterval
    let imageUrl: String?
    let title: String
    let url: String
    let body: String
    let source: String
    let categories: String

    init(map: Map) throws {
        let idString: String = try map.value("id")
        guard let idInt = Int(idString) else {
            throw NetworkManager.ObjectMapperError.mappingError
        }
        id = idInt

        timestamp = try map.value("published_on")
        imageUrl = try? map.value("imageurl")
        title = try map.value("title")
        url = try map.value("url")
        body = try map.value("body")
        source = try map.value("source")
        categories = try map.value("categories")
    }

}
