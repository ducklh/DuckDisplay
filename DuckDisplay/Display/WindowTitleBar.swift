import SwiftUI

struct WindowTitleBar: View {
    let window: WindowModel
    let onMinimize: () -> Void
    let onMaximize: () -> Void
    let onClose: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: (CGSize) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: WorkspaceApplication(id: window.applicationID)?.symbol ?? "app")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.cyan)
            Text(window.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { onDragChanged($0.translation) }
                        .onEnded { onDragEnded($0.translation) }
                )
            Spacer(minLength: 12)
            control("minus", label: "Minimize", action: onMinimize)
            control(window.isMaximized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right", label: window.isMaximized ? "Restore" : "Maximize", action: onMaximize)
            control("xmark", label: "Close", action: onClose, tint: .red.opacity(0.85))
        }
        .padding(.leading, 16)
        .padding(.trailing, 10)
        .frame(height: 44)
        .background(
            LinearGradient(
                colors: window.isFocused
                    ? [Color(red: 0.13, green: 0.19, blue: 0.25), Color(red: 0.10, green: 0.14, blue: 0.19)]
                    : [Color(red: 0.12, green: 0.15, blue: 0.19), Color(red: 0.095, green: 0.12, blue: 0.16)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
        }
    }

    private func control(
        _ symbol: String,
        label: String,
        action: @escaping () -> Void,
        tint: Color = .white.opacity(0.72)
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 27, height: 27)
                .background(.white.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
