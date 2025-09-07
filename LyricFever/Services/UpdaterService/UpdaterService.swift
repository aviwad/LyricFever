//
//  UpdaterService.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//


import Foundation
import Sparkle

class UpdaterService {
    // Sparkle / Update Controller
    let updaterController: SPUStandardUpdaterController
    
    init() {
        // Setup Sparkle updater service
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    @MainActor
    var urgentUpdateExists: Bool {
        get async {
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let url = URL(string: "https://raw.githubusercontent.com/aviwad/LyricFeverHomepage/master/urgentUpdateVersion.md")  {
                let request = URLRequest(url: url)
                let urlResponseAndData = try? await URLSession(configuration: .ephemeral).data(for: request)
                if let urlResponseAndData, let internetUrgentVersionString = String(bytes:urlResponseAndData.0, encoding: .utf8), let internetUrgentVersion = Double(internetUrgentVersionString), let currentVersion = Double(version) {
                        print("current version is \(currentVersion), internet urgent version is \(internetUrgentVersion)")
                        if currentVersion < internetUrgentVersion {
                            print("NOT EQUAL")
                            return true
                        } else {
                            print("EQUAL")
                            return false
                        }
                    }
            }
            return false
        }
    }
}
