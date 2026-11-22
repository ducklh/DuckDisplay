import SwiftUI

struct DockView: View {
    let applications: [WorkspaceApplication]
    let minimizedWindows: [WindowModel]
    let launch: (WorkspaceApplication) -> Void
    let restore: (UUID) -> Void
    let showLauncher: () -> Void
    let showClock: Bool

    var body: some View {
        HStack(spacing: 14) {
            Button(action: showLauncher) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(.cyan.opacity(0.22), in: RoundedRectangle(cornerRadius: 17))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open application launcher")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    Rectangle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 1, height: 38)

                    ForEach(applications) { application in
                        Button { launch(application) } label: {
                            VStack(spacing: 4) {
                                Image(systemName: application.symbol)
                                    .font(.system(size: 20, weight: .medium))
                                    .frame(width: 48, height: 42)
                                    .foregroundStyle(.white.opacity(0.92))
                                Text(application.title)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.66))
                            }
                            .frame(minWidth: 52)
                        }
                        .buttonStyle(.plain)
                    }

                    if !minimizedWindows.isEmpty {
                        Rectangle()
                            .fill(.white.opacity(0.18))
                            .frame(width: 1, height: 38)
                        ForEach(minimizedWindows) { window in
                            Button { restore(window.id) } label: {
                                Image(systemName: WorkspaceApplication(id: window.applicationID)?.symbol ?? "app")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.75))
                                    .frame(width: 42, height: 42)
                                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Restore \(window.title)")
                        }
                    }
                }
            }
            Spacer(minLength: 8)
            if showClock {
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    Text(context.date, style: .time)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.76))
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 8)
        .frame(maxWidth: 980)
    }
}
