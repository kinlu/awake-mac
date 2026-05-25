import Foundation

enum ScreenLocker {
    static func lockScreen() {
        typealias SACLockScreenImmediateFunc = @convention(c) () -> Void

        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login",
            RTLD_LAZY
        ) else {
            return
        }

        defer { dlclose(handle) }

        guard let sym = dlsym(handle, "SACLockScreenImmediate") else {
            return
        }

        let lockScreen = unsafeBitCast(sym, to: SACLockScreenImmediateFunc.self)
        lockScreen()
    }
}
