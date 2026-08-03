import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case menu
    case foundation
    case finder
    case permissions
    case about

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .general:
            "General"
        case .menu:
            "Menu"
        case .foundation:
            "Foundation"
        case .finder:
            "Finder"
        case .permissions:
            "Permissions"
        case .about:
            "About"
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            "gearshape"
        case .menu:
            "menubar.rectangle"
        case .foundation:
            "bolt"
        case .finder:
            "folder"
        case .permissions:
            "checkmark.shield"
        case .about:
            "info.circle"
        }
    }

    var keyboardKey: KeyEquivalent {
        switch self {
        case .general:
            "1"
        case .menu:
            "2"
        case .foundation:
            "3"
        case .finder:
            "4"
        case .permissions:
            "5"
        case .about:
            "6"
        }
    }
}
