//
//  AppleMusicPrefetcher.swift
//  Lyric Fever
//
//  Background album-wide lyric prefetcher for Apple Music. On every track
//  change, warmAlbum enumerates the album's tracks via the MusicKit catalog
//  API, diffs against CoreData, and fetches lyrics for any uncached track using
//  a bounded TaskGroup (cap = 4 concurrent fetches). All failures are silent —
//  demand-fetch on the next play of an uncached track recovers automatically.
//

import Foundation
import MusicKit
import CoreData

actor AppleMusicPrefetcher {
    private let container: NSPersistentContainer
    private let provider: AppleMusicLyricProvider
    private let concurrencyCap = 4

    init(container: NSPersistentContainer, provider: AppleMusicLyricProvider) {
        self.container = container
        self.provider = provider
    }

    /// Fetch lyrics for every track on the album that isn't already cached.
    func warmAlbum(albumID: String) async {
        guard await AppleMusicAuthManager.shared.isAuthorized else { return }
        guard !albumID.isEmpty else { return }

        // 1. Enumerate album tracks via MusicDataRequest
        let albumTracks = await enumerateAlbumTracks(albumID: albumID)
        guard !albumTracks.isEmpty else { return }

        // 2. Diff against CoreData
        let alreadyCached = await cachedAppleMusicIDs(in: albumTracks.map { $0.id })
        let toFetch = albumTracks.filter { !alreadyCached.contains($0.id) }
        guard !toFetch.isEmpty else { return }

        print("AppleMusicPrefetcher.warmAlbum: \(toFetch.count) new tracks for album \(albumID)")

        // 3. Bounded TaskGroup with concurrency cap
        await withTaskGroup(of: Void.self) { group in
            var active = 0
            var iter = toFetch.makeIterator()
            while let next = iter.next() {
                if active >= concurrencyCap {
                    await group.next()
                    active -= 1
                }
                group.addTask { [provider] in
                    let result = try? await provider.fetchNetworkLyrics(
                        trackName: next.name,
                        trackID: next.id,
                        currentlyPlayingArtist: next.artistName,
                        currentAlbumName: next.albumName
                    )
                    await self.persist(result: result, albumTrack: next, albumID: albumID)
                }
                active += 1
            }
        }
    }

    // MARK: - Helpers

    private struct AlbumTrack {
        let id: String
        let name: String
        let artistName: String?
        let albumName: String?
    }

    private func enumerateAlbumTracks(albumID: String) async -> [AlbumTrack] {
        guard let url = URL(string: "https://api.music.apple.com/v1/catalog/{{storefront}}/albums/\(albumID)?include=tracks") else {
            return []
        }
        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        do {
            let response = try await request.response()
            guard response.urlResponse.statusCode == 200 else { return [] }
            struct AlbumEnvelope: Decodable {
                struct Datum: Decodable {
                    struct Relationships: Decodable {
                        struct Tracks: Decodable {
                            struct Item: Decodable {
                                struct Attributes: Decodable {
                                    let name: String
                                    let artistName: String?
                                    let albumName: String?
                                }
                                let id: String
                                let attributes: Attributes
                            }
                            let data: [Item]
                        }
                        let tracks: Tracks
                    }
                    let relationships: Relationships
                }
                let data: [Datum]
            }
            let envelope = try JSONDecoder().decode(AlbumEnvelope.self, from: response.data)
            return envelope.data.first?.relationships.tracks.data.map {
                AlbumTrack(
                    id: $0.id,
                    name: $0.attributes.name,
                    artistName: $0.attributes.artistName,
                    albumName: $0.attributes.albumName
                )
            } ?? []
        } catch {
            return []
        }
    }

    @MainActor
    private func cachedAppleMusicIDs(in candidates: [String]) -> Set<String> {
        let ctx = container.viewContext
        let request = SongObject.fetchRequest()
        request.predicate = NSPredicate(format: "appleMusicID IN %@", candidates)
        let existing = (try? ctx.fetch(request)) ?? []
        return Set(existing.compactMap { $0.appleMusicID })
    }

    @MainActor
    private func persist(result: NetworkFetchReturn?, albumTrack: AlbumTrack, albumID: String) {
        let ctx = container.viewContext
        let lines = result?.lyrics ?? []
        let song = SongObject(from: lines, with: ctx, trackID: albumTrack.id, trackName: albumTrack.name)
        song.appleMusicID = albumTrack.id
        song.albumID = albumID
        try? ctx.save()
    }
}
