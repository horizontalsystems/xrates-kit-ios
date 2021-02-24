import ObjectMapper

class JsonFileParser {

    func parse<T: Decodable>(filename: String) throws -> T {
        guard let bundle = Bundle(for: XRatesKit.self).url(forResource: "XRatesKit", withExtension: "bundle").flatMap { Bundle(url: $0) },
              let path = bundle.path(forResource: filename, ofType: "json") else {
            throw ParseError.notFound
        }

        let text = try String(contentsOfFile: path, encoding: .utf8)
        if let textData = text.data(using: .utf8) {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let object: T = try! decoder.decode(T.self, from: textData)

            return object
        }
        throw ParseError.cantParse
    }

}

extension JsonFileParser {

    enum ParseError: Error {
        case notFound
        case cantParse
    }

}
