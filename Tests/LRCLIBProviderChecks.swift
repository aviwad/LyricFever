// Standalone checks: run Tests/run-lrclib-checks.sh from the repository root.
// The real provider is compiled against minimal app-model stubs and a mock URLProtocol.
import Foundation

@MainActor final class ViewModel {
    static let shared = ViewModel()
    var duration = 272_000
}

struct NetworkFetchReturn {
    let lyrics: [LyricLine]
    let colorData: Int32?
}

final class MockProtocol: URLProtocol {
    static var scenario = "fallback"
    static var requests: [URL] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let url = request.url!
        Self.requests.append(url)
        let record: (Int, String)
        if url.host == "itunes.apple.com" && url.path == "/search" {
            record = (200, """
            {"results":[{"trackId":100,"artistId":200,"trackName":"情人知己","artistName":"葉蒨文","collectionName":"精选","trackTimeMillis":272000}]}
            """)
        } else if url.host == "itunes.apple.com" && url.path == "/lookup" {
            record = (200, """
            {"results":[{"trackId":100,"artistId":200,"artistName":"Sally Yeh"}]}
            """)
        } else if url.host == "lrclib.net" && url.path == "/api/get" {
            record = Self.scenario == "exact" ? (200, Self.lyric(id: 1, words: "first")) : (404, "{}")
        } else if url.host == "lrclib.net" && url.path == "/api/search" {
            let second = Self.scenario == "ambiguous" ? "different" : "first"
            record = (200, "[\(Self.lyric(id: 1, words: "first")),\(Self.lyric(id: 2, words: second))]")
        } else {
            record = (404, "{}")
        }
        let response = HTTPURLResponse(url: url, statusCode: record.0, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(record.1.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    private static func lyric(id: Int, words: String) -> String {
        """
        {"id":\(id),"name":"情人知己","trackName":"情人知己","artistName":"Sally Yeh","albumName":"Album","duration":272.0,"instrumental":false,"plainLyrics":"\(words)","syncedLyrics":"[00:01.00] \(words)"}
        """
    }
}

@main struct LRCLIBProviderChecks {
    @MainActor static func main() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockProtocol.self]
        let provider = LRCLIBLyricProvider(session: URLSession(configuration: config))

        func fetch(artist: String = "叶蒨文") async throws -> [LyricLine] {
            try await provider.fetchNetworkLyrics(trackName: "情人知己", trackID: "test", currentlyPlayingArtist: artist, currentAlbumName: "精选").lyrics
        }

        MockProtocol.scenario = "exact"
        MockProtocol.requests = []
        let exact = try await fetch()
        precondition(exact.count == 1)
        precondition(!MockProtocol.requests.contains(where: { $0.host == "itunes.apple.com" }))

        MockProtocol.scenario = "fallback"
        let alias = try await fetch()
        precondition(alias.count == 1, "Chinese artist alias should match")
        let wrongArtist = try await fetch(artist: "其他歌手")
        precondition(wrongArtist.isEmpty, "Do not match a different artist")
        ViewModel.shared.duration = 290_000
        let wrongDuration = try await fetch()
        precondition(wrongDuration.isEmpty, "Do not match a different duration")
        ViewModel.shared.duration = 272_000

        MockProtocol.scenario = "ambiguous"
        let ambiguous = try await fetch()
        precondition(ambiguous.isEmpty, "Do not choose between different recordings")

        let input = """
        [{"bad":true},{"id":1,"name":"Test","trackName":"Test","artistName":"Artist","albumName":"Album","duration":1.5,"instrumental":false,"plainLyrics":null,"syncedLyrics":"[00:01.00] line"},{"id":2,"name":"Test","trackName":"Test","artistName":"Artist","albumName":"Album","duration":1,"instrumental":false,"plainLyrics":"line","syncedLyrics":null}]
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PluralLRCLIBLyrics.self, from: input).lyrics
        precondition(decoded.count == 2 && decoded[0].lyrics.count == 1 && decoded[1].lyrics.isEmpty)
        print("LRCLIB provider checks passed")
    }
}
