import SwiftUI

struct DesktopCanvas: View {
    @EnvironmentObject private var workspace: WorkspaceStore
    @EnvironmentObject private var windowManager: WindowManager
    @State private var isLauncherPresented = false

    private let dockHeight: CGFloat = 88

    var body: some View {
        GeometryReader { proxy in
            let desktopBounds = CGSize(
                width: proxy.size.width,
                height: max(1, proxy.size.height - dockHeight)
            )

            ZStack(alignment: .topLeading) {
                desktopBackground

                ForEach(windowManager.visibleWindows) { window in
                    AppWindow(
                        window: window,
                        bounds: desktopBounds,
                        workspace: workspace,
                        onFocus: { windowManager.focus(window.id) },
                        onMinimize: { windowManager.minimize(window.id) },
                        onMaximize: { windowManager.toggleMaximize(window.id, in: desktopBounds) },
                        onClose: { windowManager.close(window.id) },
                        onMove: { position in
                            windowManager.move(window.id, to: position, in: desktopBounds)
                        },
                        onResize: { size in
                            windowManager.resize(window.id, to: size, in: desktopBounds)
                        }
                    )
                    .zIndex(Double(window.zIndex))
                }
                .animation(.snappy(duration: 0.22), value: windowManager.visibleWindows.map(\.id))

                if isLauncherPresented {
                    AppLauncher(
                        openApplication: { application in
                            windowManager.open(application, in: desktopBounds)
                            isLauncherPresented = false
                        }
                    )
                    .padding(.leading, 32)
                    .padding(.bottom, dockHeight + 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(Double(Int.max))
                }

                DockView(
                    applications: WorkspaceApplication.allCases,
                    minimizedWindows: windowManager.minimizedWindows,
                    launch: { application in windowManager.open(application, in: desktopBounds) },
                    restore: { windowManager.restore($0) },
                    showLauncher: {
                        withAnimation(.snappy(duration: 0.22)) {
                            isLauncherPresented.toggle()
                        }
                    },
                    showClock: workspace.showClock
                )
                .frame(height: dockHeight)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle().fill(.white.opacity(0.13)).frame(height: 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .zIndex(Double(Int.max - 1))
            }
            .onAppear {
                windowManager.updateDesktopBounds(desktopBounds)
                windowManager.openInitialWindowIfNeeded(in: desktopBounds)
            }
            .onChange(of: desktopBounds) { _, newBounds in
                windowManager.updateDesktopBounds(newBounds)
            }
        }
    }

    private var desktopBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.045, green: 0.10, blue: 0.17),
                    Color(red: 0.08, green: 0.16, blue: 0.23),
                    Color(red: 0.035, green: 0.08, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.cyan.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 620
            )
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 390, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.025))
                .rotationEffect(.degrees(-9))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 80)
                .padding(.bottom, 100)
        }
        .ignoresSafeArea()
    }
}
