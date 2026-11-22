import SwiftUI

struct ExternalWorkspaceView: View {
    @EnvironmentObject private var workspace: WorkspaceStore
    @EnvironmentObject private var externalDisplay: ExternalDisplayMonitor

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 600

            ZStack {
                Color(red: 0.055, green: 0.075, blue: 0.11)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: compact ? 18 : 28) {
                    HStack {
                        Label("DUCKDISPLAY", systemImage: "display.2")
                            .font(.system(size: compact ? 14 : 18, weight: .bold, design: .rounded))
                            .tracking(2)
                        Spacer()
                        if workspace.showClock {
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                Text(context.date, style: .time)
                                    .monospacedDigit()
                                    .font(.system(size: compact ? 16 : 20, weight: .medium))
                            }
                        }
                    }
                    .foregroundStyle(.white.opacity(0.8))

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: compact ? 10 : 14) {
                        Text(workspace.selectedPanel.rawValue.uppercased())
                            .font(.system(size: compact ? 13 : 16, weight: .semibold))
                            .tracking(3)
                            .foregroundStyle(.cyan)

                        Text(workspace.headline)
                            .font(.system(size: min(proxy.size.width * 0.055, compact ? 38 : 54), weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.65)

                        Text(workspace.note)
                            .font(.system(size: compact ? 17 : 22))
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 1050, alignment: .leading)

                    Spacer(minLength: 0)

                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Text("iPad companion workspace")
                            Spacer()
                            Text("A14 · External display")
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("iPad companion workspace")
                            Text("A14 · External display")
                        }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, min(max(proxy.size.width * 0.06, 20), 56))
                .padding(.vertical, min(max(proxy.size.height * 0.06, 20), 56))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            externalDisplay.setWorkspaceVisible(true)
        }
        .onDisappear {
            externalDisplay.setWorkspaceVisible(false)
        }
    }
}
