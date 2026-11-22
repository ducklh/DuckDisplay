import Foundation
import Combine

@MainActor
final class WorkspaceStore: ObservableObject {
    enum Panel: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case browser = "Browser"
        case notes = "Notes"
        case terminal = "Terminal"

        var id: String { rawValue }
    }

    @Published var selectedPanel: Panel = .dashboard
    @Published var headline: String = "DuckDisplay is ready"
    @Published var note: String = "Choose a panel on the iPad. The external display updates independently."
    @Published var showClock: Bool = true
}
