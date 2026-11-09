import Foundation
#if os(iOS) && !targetEnvironment(macCatalyst)
import Darwin
#endif

enum DuoDeviceDetection {
    /// Resolve once per process, independently of scenes and their geometry.
    static let isKnownDuo = isKnownDuo(modelIdentifier: modelIdentifier)

    static func isKnownDuo(modelIdentifier: String) -> Bool {
        modelIdentifier == "iPhone19,4"
    }

    private static var modelIdentifier: String {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? ""
        #else
        var systemInfo = utsname()
        guard uname(&systemInfo) == 0 else { return "" }
        return withUnsafeBytes(of: &systemInfo.machine) { bytes in
            String(decoding: bytes.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
        #endif
        #else
        return ""
        #endif
    }
}
