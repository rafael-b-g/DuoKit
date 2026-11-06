
import Observation

/// The proportions of an app window, independent of device orientation.
public enum Aspect: Hashable, Sendable {
    case portrait
    case landscape
}

/// The interface available to the app, rather than the device's physical pose.
public enum DuoLayout: Hashable, Sendable {
    case phone(Aspect)
    case pad(Aspect, PadState)

    /// The window is available, but its layout size class is not yet known.
    case unknown

    public enum PadState: Hashable, Sendable {
        case flat
        /// An active division region intersects the app window.
        case folded
    }
}

/// The physical display hosting the app window.
public enum DuoDisplay: Hashable, Sendable {
    case outer
    case inner
}

/// The physical hinge state derived from its angle, independent of interface layout.
/// Angles within one degree of closed or fully open use that endpoint state.
public enum DuoFoldState: Hashable, Sendable {
    case closed
    case partiallyOpen
    case fullyOpen

    /// System status can remain `closed` at nonzero angles on the outer display.
    /// Classify the measured angle instead; unavailable readings retain prior state.
    init?(hingeAngle: Double) {
        guard hingeAngle.isFinite else { return nil }
        let tolerance = Double.pi / 180 // One degree, expressed in radians.
        if hingeAngle <= tolerance {
            self = .closed
        } else if hingeAngle >= .pi - tolerance {
            self = .fullyOpen
        } else {
            self = .partiallyOpen
        }
    }
}

/// Live information for one window on iPhone Duo.
///
/// Install tracking at the root of each scene using `View.duoTracking()` and
/// read this instance through `EnvironmentValues.duo`. The instance stays stable
/// as the window resizes, rotates, folds, or moves between built-in displays.
@MainActor
@Observable
public final class Duo {
    public private(set) var layout: DuoLayout
    public private(set) var windowAspect: Aspect
    public private(set) var display: DuoDisplay
    public private(set) var foldState: DuoFoldState
    public private(set) var isFullScreen: Bool

    init(_ configuration: DuoConfiguration) {
        layout = configuration.layout
        windowAspect = configuration.aspect
        display = configuration.display
        foldState = configuration.foldState
        isFullScreen = configuration.isFullScreen
    }

    func update(_ configuration: DuoConfiguration) {
        // Keep each value independently observable, including derived layout.
        // Equality guards also avoid redundant notifications on older runtimes.
        if layout != configuration.layout { layout = configuration.layout }
        if windowAspect != configuration.aspect { windowAspect = configuration.aspect }
        if display != configuration.display { display = configuration.display }
        if foldState != configuration.foldState { foldState = configuration.foldState }
        if isFullScreen != configuration.isFullScreen { isFullScreen = configuration.isFullScreen }
    }
}
