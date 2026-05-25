import Foundation
import IOKit.pwr_mgt

final class PowerManager: ObservableObject {
    @Published private(set) var isEnabled = false

    private var assertionID: IOPMAssertionID = IOPMAssertionID(0)
    private var networkAssertionID: IOPMAssertionID = IOPMAssertionID(0)

    func enable() {
        guard !isEnabled else { return }

        let reason = "Awake is preventing system sleep" as CFString
        let type = kIOPMAssertPreventUserIdleSystemSleep as CFString

        let result = IOPMAssertionCreateWithName(
            type,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )

        // Also create a network assertion to keep WiFi alive
        let networkReason = "Awake is keeping network active" as CFString
        let networkType = kIOPMAssertNetworkClientActive as CFString

        let networkResult = IOPMAssertionCreateWithName(
            networkType,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            networkReason,
            &networkAssertionID
        )

        if result == kIOReturnSuccess {
            isEnabled = true
            UserDefaults.standard.set(true, forKey: "isEnabled")
        }

        // Log if network assertion failed (non-fatal)
        if networkResult != kIOReturnSuccess {
            networkAssertionID = IOPMAssertionID(0)
        }
    }

    func disable() {
        guard isEnabled else { return }

        let result = IOPMAssertionRelease(assertionID)
        if result == kIOReturnSuccess {
            assertionID = IOPMAssertionID(0)
            isEnabled = false
            UserDefaults.standard.set(false, forKey: "isEnabled")
        }

        // Release network assertion
        if networkAssertionID != IOPMAssertionID(0) {
            IOPMAssertionRelease(networkAssertionID)
            networkAssertionID = IOPMAssertionID(0)
        }
    }

    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
}
