import SwiftUI

@main
struct AwakeApp: App {
    @StateObject private var powerManager = PowerManager()
    @StateObject private var timerManager = TimerManager()
    @StateObject private var virtualDisplayManager = VirtualDisplayManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(powerManager: powerManager, timerManager: timerManager, virtualDisplayManager: virtualDisplayManager)
        } label: {
            Image(systemName: powerManager.isEnabled ? "cup.and.saucer.fill" : "moon.zzz")
        }
        .menuBarExtraStyle(.window)
    }
}
