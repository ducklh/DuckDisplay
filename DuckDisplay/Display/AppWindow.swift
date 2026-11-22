import SwiftUI

struct AppWindow: View {
    let window: WindowModel
    let bounds: CGSize
    let workspace: WorkspaceStore
    let onFocus: () -> Void
    let onMinimize: () -> Void
    let onMaximize: () -> Void
    let onClose: () -> Void
    let onMove: (CGPoint) -> Void
    let onResize: (CGSize) -> Void

    @State private var dragTranslation = CGSize.zero
    @State private var resizeTranslation = CGSize.zero
    @State private var isDraggingTitle = false
    @State private var isResizing = false

    private var displayPosition: CGPoint {
        let candidate = CGPoint(
            x: window.position.x + dragTranslation.width,
            y: window.position.y + dragTranslation.height
        )
        return WindowManagerPosition.clamp(candidate, size: window.size, bounds: bounds)
    }

    private var displaySize: CGSize {
        CGSize(
            width: min(max(window.minimumSize.width, window.size.width + resizeTranslation.width), bounds.width),
            height: min(max(window.minimumSize.height, window.size.height + resizeTranslation.height), bounds.height)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            WindowTitleBar(
                window: window,
                onMinimize: onMinimize,
                onMaximize: onMaximize,
                onClose: onClose,
                onDragChanged: { translation in
                    guard !window.isMaximized else { return }
                    dragTranslation = translation
                    if !isDraggingTitle {
                        isDraggingTitle = true
                        onFocus()
                    }
                },
                onDragEnded: { translation in
                    if !window.isMaximized {
                        onMove(
                            CGPoint(
                                x: window.position.x + translation.width,
                                y: window.position.y + translation.height
                            )
                        )
                    }
                    dragTranslation = .zero
                    isDraggingTitle = false
                }
            )

            windowContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(22)
                .background(Color(red: 0.075, green: 0.095, blue: 0.13))
                .clipped()
        }
        .frame(width: displaySize.width, height: displaySize.height)
        .background(Color(red: 0.075, green: 0.095, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(window.isFocused ? Color.cyan.opacity(0.8) : Color.white.opacity(0.16), lineWidth: window.isFocused ? 1.5 : 1)
        }
        .shadow(color: .black.opacity(window.isFocused ? 0.34 : 0.22), radius: window.isFocused ? 24 : 14, x: 0, y: 12)
        .overlay(alignment: .bottomTrailing) {
            if !window.isMaximized {
                ResizeHandle(
                    onChanged: { translation in
                        resizeTranslation = translation
                        if !isResizing {
                            isResizing = true
                            onFocus()
                        }
                    },
                    onEnded: { translation in
                        onResize(
                            CGSize(
                                width: window.size.width + translation.width,
                                height: window.size.height + translation.height
                            )
                        )
                        resizeTranslation = .zero
                        isResizing = false
                    }
                )
            }
        }
        .offset(x: displayPosition.x, y: displayPosition.y)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture(perform: onFocus)
        .animation(.snappy(duration: 0.20), value: window.isFocused)
        .animation(.snappy(duration: 0.20), value: window.size)
        .transition(.scale(scale: 0.96).combined(with: .opacity))
    }

    @ViewBuilder
    private var windowContent: some View {
        switch WorkspaceApplication(id: window.applicationID) {
        case .some(.dashboard):
            VStack(alignment: .leading, spacing: 16) {
                Label(workspace.selectedPanel.rawValue.uppercased(), systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.cyan)
                Text(workspace.headline)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(workspace.note)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(4)
                Spacer(minLength: 0)
                Label("DuckDisplay workspace", systemImage: "display.2")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.42))
            }
        case .some(.browser):
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    Text("duckdisplay.local")
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Image(systemName: "arrow.clockwise").foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(12)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 9))
                Text("A focused place for web content")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("This sample window is an app-owned surface. It does not host or move Safari or other third-party apps.")
                    .foregroundStyle(.white.opacity(0.65))
                Spacer()
            }
        case .some(.notes):
            VStack(alignment: .leading, spacing: 14) {
                Text("Workspace note")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(workspace.note)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        case .some(.terminal):
            VStack(alignment: .leading, spacing: 12) {
                Text("duckdisplay — workspace")
                    .foregroundStyle(.white.opacity(0.55))
                Text("$ status")
                    .foregroundStyle(.green)
                Text("Window manager ready\nExternal scene: non-interactive\nInput: iPad control surface")
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("$ _").foregroundStyle(.green)
            }
            .font(.system(.body, design: .monospaced))
        case .none:
            ContentUnavailableView("Unknown app", systemImage: "questionmark.square.dashed")
        }
    }
}

private struct ResizeHandle: View {
    let onChanged: (CGSize) -> Void
    let onEnded: (CGSize) -> Void

    var body: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.62))
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { onChanged($0.translation) }
                    .onEnded { onEnded($0.translation) }
            )
            .padding(3)
    }
}

private enum WindowManagerPosition {
    static func clamp(_ point: CGPoint, size: CGSize, bounds: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(0, point.x), max(0, bounds.width - size.width)),
            y: min(max(0, point.y), max(0, bounds.height - size.height))
        )
    }
}
