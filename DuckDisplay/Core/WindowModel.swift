import CoreGraphics
import Foundation

enum WorkspaceApplication: String, CaseIterable, Identifiable {
    case dashboard
    case browser
    case notes
    case terminal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .browser: "Browser"
        case .notes: "Notes"
        case .terminal: "Terminal"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .browser: "safari"
        case .notes: "note.text"
        case .terminal: "terminal"
        }
    }

    var minimumSize: CGSize {
        CGSize(width: 280, height: 190)
    }

    var defaultSize: CGSize {
        switch self {
        case .dashboard: CGSize(width: 560, height: 380)
        case .browser: CGSize(width: 680, height: 460)
        case .notes: CGSize(width: 430, height: 350)
        case .terminal: CGSize(width: 560, height: 330)
        }
    }

    init?(id: String) {
        self.init(rawValue: id)
    }
}

struct WindowModel: Identifiable, Equatable {
    let id: UUID
    let applicationID: String
    var title: String
    var position: CGPoint
    var size: CGSize
    let minimumSize: CGSize
    var zIndex: Int
    var isMinimized: Bool
    var isMaximized: Bool
    var isFocused: Bool
    var previousFrame: CGRect?
}
