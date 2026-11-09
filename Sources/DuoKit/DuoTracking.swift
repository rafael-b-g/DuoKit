import Observation
import SwiftUI

extension EnvironmentValues {
    /// Information for the tracked window, or `nil` on unsupported devices.
    ///
    /// Known Duo hardware receives a model immediately when tracking is installed.
    /// Other models remain `nil` until a hinge is detected. Individual readings
    /// are optional while pending, and layout starts as `.unknown`.
    @Entry public var duo: Duo? = nil
}

extension View {
    /// Tracks the containing window and supplies its `Duo` to descendant views.
    ///
    /// Apply once to the root view inside each `WindowGroup`. Tracking uses
    /// native iOS 27.1 APIs; earlier systems and other platforms supply `nil`.
    /// - Parameters:
    ///   - closedThreshold: Maximum angle considered closed. Defaults to 1°.
    ///   - fullyOpenThreshold: Minimum angle considered fully open. Defaults to 179°.
    ///
    /// Thresholds must be finite and satisfy
    /// `0° ≤ closedThreshold < fullyOpenThreshold ≤ 180°`.
    public func duoTracking(
        closedThreshold: Angle = .degrees(1),
        fullyOpenThreshold: Angle = .degrees(179)
    ) -> some View {
        modifier(DuoTrackingModifier(thresholds: DuoFoldThresholds(
            closed: closedThreshold.radians,
            fullyOpen: fullyOpenThreshold.radians
        )))
    }
}

private struct DuoTrackingModifier: ViewModifier {
    let thresholds: DuoFoldThresholds
    @State private var tracker = DuoTracker()

    func body(content: Content) -> some View {
        content
            .environment(\.duo, tracker.duo)
            .background {
                #if os(iOS) && !targetEnvironment(macCatalyst)
                if #available(iOS 27.1, *) {
                    DuoWindowReader(tracker: tracker, thresholds: thresholds)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                #endif
            }
    }
}

/// Keeps hardware detection separate from the window model's readiness.
@MainActor
@Observable
final class DuoTracker {
    private(set) var duo: Duo?
    @ObservationIgnored private var windowID: ObjectIdentifier?

    init(isKnownDuo: Bool = DuoDeviceDetection.isKnownDuo) {
        duo = isKnownDuo ? Duo() : nil
    }

    func detectHinge(foldState: DuoFoldState? = nil) {
        if duo == nil { duo = Duo() }
        if let foldState { duo?.updateFoldState(foldState) }
    }

    func update(_ configuration: DuoConfiguration, windowID: ObjectIdentifier) {
        if let previous = self.windowID, previous != windowID { duo = nil }
        self.windowID = windowID
        detectHinge()
        duo?.update(configuration)
    }
}
