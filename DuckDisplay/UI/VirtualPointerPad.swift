import SwiftUI

struct VirtualPointerPad: View {
    @ObservedObject var pointerManager: PointerManager
    let mouseInput: MouseInputHandler
    let workspaceBounds: CGSize

    @EnvironmentObject private var windowManager: WindowManager
    @FocusState private var isKeyboardFocused: Bool
    @State private var isPressing = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)

                VStack(spacing: 6) {
                    Image(systemName: "cursorarrow")
                        .font(.title2)
                    Text("Workspace pointer pad")
                        .font(.subheadline.weight(.medium))
                    Text("Move, click, or drag here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if pointerManager.isVisible,
                   let localPosition = PointerCoordinateMapper.convert(
                       pointerManager.position,
                       from: CGRect(origin: .zero, size: workspaceBounds),
                       to: CGRect(origin: .zero, size: proxy.size)
                   ) {
                    Image(systemName: "arrow.up.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.cyan)
                        .position(localPosition)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.secondary.opacity(0.35), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    mouseInput.movePointer(
                        to: location,
                        from: proxy.size,
                        in: workspaceBounds
                    )
                case .ended:
                    mouseInput.pointerExited()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressing {
                            isPressing = true
                            isKeyboardFocused = true
                            mouseInput.beginPress(
                                at: value.startLocation,
                                from: proxy.size,
                                in: workspaceBounds
                            )
                        }
                        mouseInput.movePointer(
                            to: value.location,
                            from: proxy.size,
                            in: workspaceBounds
                        )
                    }
                    .onEnded { value in
                        mouseInput.endPress(
                            at: value.location,
                            from: proxy.size,
                            in: workspaceBounds
                        )
                        isPressing = false
                    }
            )
            .onKeyPress(.escape) { _ in
                mouseInput.cancel(in: workspaceBounds)
                isPressing = false
                return .handled
            }
            .focusable()
            .focused($isKeyboardFocused)
            .contextMenu {
                if let window = WindowHitTesting.window(
                    at: pointerManager.position,
                    in: windowManager.visibleWindows
                ) {
                    Button("Focus \(window.title)", systemImage: "scope") {
                        mouseInput.interactionController.focus(window.id)
                    }
                    Button(
                        window.isMaximized ? "Restore Size" : "Maximize",
                        systemImage: "arrow.up.left.and.arrow.down.right"
                    ) {
                        mouseInput.interactionController.toggleMaximize(
                            window.id,
                            in: workspaceBounds
                        )
                    }
                    Button("Minimize", systemImage: "minus.rectangle") {
                        mouseInput.interactionController.minimize(window.id)
                    }
                    Button("Close", systemImage: "xmark", role: .destructive) {
                        mouseInput.interactionController.close(window.id)
                    }
                } else {
                    Text("No window under pointer")
                }
            }
            .accessibilityLabel("Virtual workspace pointer pad")
        }
        .frame(height: 132)
    }
}
