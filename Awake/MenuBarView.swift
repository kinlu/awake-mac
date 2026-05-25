import SwiftUI
import ServiceManagement

struct MenuBarView: View {
    @ObservedObject var powerManager: PowerManager
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var virtualDisplayManager: VirtualDisplayManager
    @State private var launchAtLogin = false
    @State private var hoveredRow: String?

    private let sectionSpacing: CGFloat = 14
    private let sectionCornerRadius: CGFloat = 14
    private let rowCornerRadius: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            capsuleButton("awake-lock") {
                Label("Awake & Lock", systemImage: "lock.shield")
                    .font(.headline.weight(.semibold))
            } action: {
                powerManager.enable()
                virtualDisplayManager.enable()
                ScreenLocker.lockScreen()
            }

            section {
                row("awake", isActive: powerManager.isEnabled) {
                    Toggle(isOn: Binding(
                        get: { powerManager.isEnabled },
                        set: { newValue in
                            if newValue {
                                powerManager.enable()
                            } else {
                                powerManager.disable()
                                timerManager.stop()
                            }
                        }
                    )) {
                        Label(
                            powerManager.isEnabled ? "Awake (On)" : "Awake (Off)",
                            systemImage: powerManager.isEnabled ? "cup.and.saucer.fill" : "moon.zzz"
                        )
                    }
                }

                if timerManager.isRunning {
                    statusText("Auto-off in \(timerManager.formattedRemaining)")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("Timer")
                section {
                    ForEach(TimerDuration.allCases) { duration in
                        Button {
                            if duration == .off {
                                timerManager.stop()
                            } else {
                                if !powerManager.isEnabled {
                                    powerManager.enable()
                                }
                                timerManager.start(duration: duration)
                            }
                        } label: {
                            row(
                                "timer-\(duration.rawValue)",
                                isSelected: timerManager.selectedDuration == duration && (duration == .off || timerManager.isRunning)
                            ) {
                                HStack {
                                    Text(duration.label)
                                    Spacer()
                                    if timerManager.selectedDuration == duration && (duration == .off || timerManager.isRunning) {
                                        Image(systemName: "checkmark")
                                            .font(.body.weight(.semibold))
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            section {
                row("virtual-display", isActive: virtualDisplayManager.isEnabled) {
                    Toggle(isOn: Binding(
                        get: { virtualDisplayManager.isEnabled },
                        set: { newValue in
                            if newValue {
                                virtualDisplayManager.enable()
                            } else {
                                virtualDisplayManager.disable()
                            }
                        }
                    )) {
                        Label(
                            virtualDisplayManager.isEnabled ? "Virtual Display (On)" : "Virtual Display (Off)",
                            systemImage: virtualDisplayManager.isEnabled ? "display" : "display.trianglebadge.exclamationmark"
                        )
                    }
                }

                if virtualDisplayManager.isEnabled {
                    statusText("Fake display for clamshell mode")
                }

                row("launch-at-login") {
                    Toggle(isOn: $launchAtLogin) {
                        Text("Launch at Login")
                    }
                    .onChange(of: launchAtLogin) { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
                }
            }

            capsuleButton("quit") {
                Text("Quit Awake")
            } action: {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(minWidth: 300)
        .onDisappear {
            hoveredRow = nil
        }
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            timerManager.onTimerExpired = {
                powerManager.disable()
            }

            if UserDefaults.standard.bool(forKey: "isEnabled") {
                powerManager.enable()
            }
        }
    }

    private func handleHover(for rowID: String, isHovering: Bool) {
        if isHovering {
            hoveredRow = rowID
        } else if hoveredRow == rowID {
            hoveredRow = nil
        }
    }

    private func rowFill(for rowID: String, isSelected: Bool = false, isActive: Bool = false) -> Color {
        if isSelected {
            return Color.accentColor.opacity(0.24)
        }
        if isActive {
            return Color.accentColor.opacity(0.16)
        }
        if hoveredRow == rowID {
            return Color.primary.opacity(0.10)
        }
        return Color.clear
    }

    private func capsuleButton(
        _ rowID: String,
        @ViewBuilder label: () -> some View,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Spacer()
            Button(action: action) {
                label()
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .background(
                Capsule()
                    .fill(hoveredRow == rowID ? Color.primary.opacity(0.14) : Color.primary.opacity(0.09))
            )
            .onHover { isHovering in
                handleHover(for: rowID, isHovering: isHovering)
            }
            Spacer()
        }
    }

    private func section<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            content()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: sectionCornerRadius, style: .continuous)
                        .stroke(Color.primary.opacity(0.08))
                )
        )
    }

    private func row<Content: View>(
        _ rowID: String,
        isSelected: Bool = false,
        isActive: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: rowCornerRadius, style: .continuous)
                    .fill(rowFill(for: rowID, isSelected: isSelected, isActive: isActive))
            )
            .contentShape(RoundedRectangle(cornerRadius: rowCornerRadius, style: .continuous))
            .onHover { isHovering in
                handleHover(for: rowID, isHovering: isHovering)
            }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
    }

    private func statusText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.bottom, 2)
    }
}
