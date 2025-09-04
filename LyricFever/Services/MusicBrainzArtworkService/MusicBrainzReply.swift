//
//  MusicBrainzReply.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-05.
//


struct MusicBrainzReply: Codable {
    let created: String
    let count, offset: Int
    let releases: [MusicBrainzRelease]
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.created = try container.decode(String.self, forKey: .created)
            self.count = try container.decode(Int.self, forKey: .count)
            self.offset = try container.decode(Int.self, forKey: .offset)
            
            // Decode all releases and filter out "Bootleg" ones
            let allReleases = try container.decode([MusicBrainzRelease].self, forKey: .releases)
            self.releases = allReleases.filter { $0.status != "Bootleg" }
    }
    
    struct MusicBrainzRelease: Codable {
        let id: String
        let status: String?
        
        enum CodingKeys: CodingKey {
            case id,status
        }
        
        init(from decoder: any Decoder) throws {
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(String.self, forKey: .id)
            self.status = try? container.decode(String.self, forKey: .status)
        }
    }

}
