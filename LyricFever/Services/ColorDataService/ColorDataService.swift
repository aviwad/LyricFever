//
//  ColorDataService.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-04.
//
@MainActor
class ColorDataService {
    static func saveColorToCoreData(trackID: String, songColor: Int) {
        let newColorMapping = IDToColor(context: ViewModel.shared.coreDataContainer.viewContext)
        newColorMapping.id = trackID
        newColorMapping.songColor = Int32(songColor)
        do {
            try ViewModel.shared.coreDataContainer.viewContext.save()
            print("ColorDataService: Successfully saved color \(songColor) for trackID \(trackID)")
        } catch {
            print("ColorDataService: Couldn't save color mapping to CoreData: \(error)")
        }
    }
}
