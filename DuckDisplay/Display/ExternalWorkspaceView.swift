import SwiftUI

struct ExternalWorkspaceView: View {
    @EnvironmentObject private var workspace: WorkspaceStore

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 0.055, green: 0.075, blue: 0.11)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Label("DUCKDISPLAY", systemImage: "display.2")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .tracking(2)
                        Spacer()
                        if workspace.showClock {
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                Text(context.date, style: .time)
                                    .monospacedDigit()
                                    .font(.system(size: 20, weight: .medium))
                            }
                        }
                    }
                    .foregroundStyle(.white.opacity(0.8))

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 14) {
                        Text(workspace.selectedPanel.rawValue.uppercased())
                            .font(.system(size: 16, weight: .semibold))
                            .tracking(3)
                            .foregroundStyle(.cyan)

                        Text(workspace.headline)
                            .font(.system(size: min(proxy.size.width * 0.055, 54), weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.65)

                        Text(workspace.note)
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 1050, alignment: .leading)

                    Spacer(minLength: 0)

                    HStack {
                        Text("iPad companion workspace")
                        Spacer()
                        Text("A14 · External display")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                }
                .padding(48)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .preferredColorScheme(.dark)
    }
}
