import Observation
import SwiftUI

extension EnvironmentValues {
    /// Information for the tracked window, or `nil` on unsupported devices.
    ///
    /// Also `nil` before the first valid window and hinge readings arrive.
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

/// Only replacement of the window model invalidates the tracking modifier.
@MainActor
@Observable
final class DuoTracker {
    private(set) var duo: Duo?
    @ObservationIgnored private var windowID: ObjectIdentifier?

    func update(_ configuration: DuoConfiguration, windowID: ObjectIdentifier) {
        if self.windowID == windowID, let duo {
            duo.update(configuration)
        } else {
            self.windowID = windowID
            duo = Duo(configuration)
        }
    }
}
