import SwiftUI

struct AppLauncher: View {
    let openApplication: (WorkspaceApplication) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPLICATIONS")
                .font(.caption.weight(.bold))
                .tracking(1.8)
                .foregroundStyle(.white.opacity(0.55))
                .padding(.horizontal, 8)

            ForEach(WorkspaceApplication.allCases) { application in
                Button { openApplication(application) } label: {
                    Label(application.title, systemImage: application.symbol)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 230)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.32), radius: 24, y: 12)
    }
}
