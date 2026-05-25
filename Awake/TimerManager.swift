import Foundation
import Combine

enum TimerDuration: Int, CaseIterable, Identifiable {
    case off = 0
    case oneHour = 3600
    case twoHours = 7200
    case fourHours = 14400

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .off: return "Off"
        case .oneHour: return "1h"
        case .twoHours: return "2h"
        case .fourHours: return "4h"
        }
    }
}

final class TimerManager: ObservableObject {
    @Published private(set) var remainingSeconds: Int = 0
    @Published var selectedDuration: TimerDuration = .off

    var onTimerExpired: (() -> Void)?

    private var timer: AnyCancellable?

    var formattedRemaining: String {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var isRunning: Bool {
        timer != nil
    }

    func start(duration: TimerDuration) {
        stop()
        guard duration != .off else { return }

        selectedDuration = duration
        remainingSeconds = duration.rawValue

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.stop()
                    self.onTimerExpired?()
                }
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        remainingSeconds = 0
        selectedDuration = .off
    }
}
