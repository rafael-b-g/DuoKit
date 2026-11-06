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
    public func duoTracking() -> some View {
        modifier(DuoTrackingModifier())
    }
}

private struct DuoTrackingModifier: ViewModifier {
    @State private var tracker = DuoTracker()

    func body(content: Content) -> some View {
        content
            .environment(\.duo, tracker.duo)
            .background {
                #if os(iOS) && !targetEnvironment(macCatalyst)
                if #available(iOS 27.1, *) {
                    DuoWindowReader(tracker: tracker)
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
