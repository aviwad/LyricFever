extension String {
    func spotifyProcessedUrl() -> String? {
        let components = self.components(separatedBy: ":")
        guard components.count > 2 else { return nil }
        if components[1] == "episode" {
            return nil
        }
        if components[1] == "local" {
            var localTrackId = components.dropFirst(2).dropLast().joined(separator: ":")
            // Ensures only Spotify tracks have a length of 22
            if localTrackId.count == 22 {
                localTrackId.append("_")
            }
            return localTrackId
        } else {
            return components.dropFirst(2).joined(separator: ":")
        }
    }
}
