//
//  KaraokeLineMode.swift
//  Lyric Fever
//

import SwiftUI

// How many lyric lines the karaoke panel shows, and how they move between line changes.
enum KaraokeLineMode: Int, CaseIterable, Identifiable {
    // One line at a time. The original Lyric Fever behaviour.
    case single = 0
    // Current line on top, the upcoming one previewed below it. Advancing a line slides the rows
    // upward: the previewed line rises into the current slot rather than jumping there, and the
    // line after it slides in from below. Also previews line 1 during the intro, before playback
    // has reached any line at all.
    case upcoming = 1
    // Karaoke-machine style. Two fixed slots take turns holding lines, so the line being sung never
    // moves — the highlight jumps to the other slot instead, and the slot it leaves immediately
    // loads the line after next.
    case alternating = 2

    var id: Int { rawValue }

    var localizedName: LocalizedStringKey {
        switch self {
        case .single:
            return "Single line"
        case .upcoming:
            return "Two lines: preview the next line"
        case .alternating:
            return "Two lines: KTV style, alternating"
        }
    }
}
