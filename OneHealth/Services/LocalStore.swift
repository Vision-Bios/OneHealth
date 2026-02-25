import Foundation

enum LocalStore {
    static func load<T: Decodable>(_ filename: String, as type: T.Type) -> T? {
        guard let url = fileURL(filename) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }

    static func save<T: Encodable>(_ data: T, filename: String) {
        guard let url = fileURL(filename) else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let encoded = try? encoder.encode(data) else { return }
        try? encoded.write(to: url, options: [.atomic])
    }

    private static func fileURL(_ filename: String) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(filename)
    }
}
