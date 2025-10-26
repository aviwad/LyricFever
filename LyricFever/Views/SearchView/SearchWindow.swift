//
//  SearchWindow.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-09-02.
//

import SwiftUI

struct SearchWindow: View {
    @Environment(ViewModel.self) var viewmodel
    @State var trackName: String = ""
    @State var currentProvider: String = ""
    @State var artistName: String = ""
    @State private var searchResults: [SongResult] = []
    @State var isFetching = false
    @State private var selectedLyric: UUID? = nil
    @State private var lyricsAreApplied: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil
    
    private let overlayHeight: CGFloat = 250
    
    @ViewBuilder
    var searchControlsView: some View {
        HStack {
            Text("Song Name")
            TextField("Song Name:", text: $trackName)
                .padding(.trailing, 30)
            Text("Artist Name:")
            TextField("Artist Name", text: $artistName)
                .padding(.trailing, 30)
            Button {
                searchResults = []
                // cancel any stale search task
                searchTask?.cancel()
                searchTask = Task { @MainActor in
                    do {
                        try await searchLyrics()
                    } catch {
                        print("Search Task Error: \(error)")
                    }
                }
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .disabled(isFetching)
            .keyboardShortcut(.defaultAction)
            .tint(.primary)
        }
    }
    
    @ViewBuilder
    var searchResultsView: some View {
        Table(searchResults, selection: $selectedLyric) {
            TableColumn("Lyric Provider", value: \.lyricType)
            TableColumn("Song Name", value: \.songName)
            TableColumn("Album Name", value: \.albumName)
            TableColumn("Artist Name", value: \.artistName)
        }
    }
    
    @ViewBuilder
    var selectedLyricView: some View {
        if let selectedLyric, let selectedLyricLyric = searchResults.first(where: { $0.id == selectedLyric}) {
            HStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(selectedLyricLyric.lyrics, id: \.id) { lyric in
                            HStack {
                                Text(formattedTimestamp(ms: lyric.startTimeMS))
                                Text(lyric.words)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(.black)
                .frame(width: 400)
                Spacer()
                Button {
                    let cleanLyrics = NetworkFetchReturn(lyrics: selectedLyricLyric.lyrics, colorData: nil).processed(withSongName: trackName, duration: viewmodel.duration).lyrics
                    viewmodel.setNewLyricsColorTranslationRomanizationAndStartUpdater(with: cleanLyrics)
                    guard let spotifyID = viewmodel.currentlyPlaying else {
                        return
                    }
                    SongObject(from: cleanLyrics, with: viewmodel.coreDataContainer.viewContext, trackID: spotifyID, trackName: trackName)
                    viewmodel.saveCoreData()
                    lyricsAreApplied = true
                } label: {
                    Label(lyricsAreApplied ? "Lyrics were applied!" : "Click to Use", systemImage: "checkmark")
                        .bold()
                        .frame(width: 230)
                }
                .buttonStyle(.borderedProminent)
                .disabled(lyricsAreApplied)
                .tint(lyricsAreApplied ? .gray : .green)
            }
            .padding()
            .transition(.move(edge: .bottom))
            .frame(maxWidth: .infinity)
            .frame(height: overlayHeight)
            .background(
                .thinMaterial
            )
        }
    }
    
    // Helper to format milliseconds as mm:ss
    private func formattedTimestamp(ms: TimeInterval) -> String {
        let totalSeconds = Int(ms) / 1000
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(totalSeconds)) ?? "00:00"
    }
    
    @ViewBuilder
    var searchWindow: some View {
        VStack {
            searchControlsView
            ZStack {
                searchResultsView
                loadingView
            }
        }
        // Reserve space when the bottom overlay is visible so rows aren’t hidden
        .padding(.bottom, selectedLyric != nil ? overlayHeight : 0)
        .padding()
    }
    
    @ViewBuilder
    var loadingView: some View {
        if isFetching {
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 80, height: 80)
                .cornerRadius(10)
            ProgressView()
        }
    }
    
    func searchLyrics() async throws {
        isFetching = true
        defer { isFetching = false }
        searchResults = []
        for lyricProvider in viewmodel.allNetworkLyricProvidersForSearch {
            if Task.isCancelled { return }
            currentProvider = lyricProvider.providerName
            let results = try await lyricProvider.search(trackName: trackName, artistName: artistName)
            if Task.isCancelled { return }
            searchResults.append(contentsOf: results)
        }
    }
    
    var body: some View {
        searchWindow
            .overlay(
                VStack {
                    selectedLyricView.ignoresSafeArea()
                }
                    .animation(.snappy(duration: 0.2), value: selectedLyric)
                , alignment: .bottom)
            .onAppear {
                trackName = viewmodel.currentlyPlayingName ?? ""
                artistName = viewmodel.currentlyPlayingArtist ?? ""
                // start initial search, canceling any potential concurrent search task
                searchTask?.cancel()
                searchTask = Task { @MainActor in
                    do {
                        try await searchLyrics()
                    } catch {
                        print("Search task error: \(error)")
                    }
                }
            }
            .onChange(of: selectedLyric) {
                lyricsAreApplied = false
            }
            .onChange(of: viewmodel.currentlyPlaying) {
                if viewmodel.currentlyPlaying == nil {
                    return
                }
                // cancel stale search tasks
                searchTask?.cancel()
                isFetching = false
                searchResults = []
                lyricsAreApplied = false
            }
            .onChange(of: viewmodel.currentlyPlayingName) { oldName, newName in
                if let newName {
                    trackName = newName
                }
            }
            .onChange(of: viewmodel.currentlyPlayingArtist) { oldArtist, newArtist in
                if let newArtist {
                    artistName = newArtist
                }
            }
            .tint(viewmodel.currentBackground)
        .navigationTitle("Searching for \(viewmodel.currentlyPlayingName ?? "-") by \(viewmodel.currentlyPlayingArtist ?? "-")")
        .presentedWindowToolbarStyle(.unified)
    }
}
