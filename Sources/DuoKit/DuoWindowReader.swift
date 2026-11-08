#if os(iOS) && !targetEnvironment(macCatalyst)
import SwiftUI
import UIKit

@available(iOS 27.1, *)
struct DuoWindowReader: UIViewRepresentable {
    let tracker: DuoTracker
    let thresholds: DuoFoldThresholds

    func makeUIView(context: Context) -> DuoWindowProbe {
        DuoWindowProbe(tracker: tracker, thresholds: thresholds)
    }

    func updateUIView(_ view: DuoWindowProbe, context: Context) {
        view.updateThresholds(thresholds)
        view.setNeedsLayout()
    }

    static func dismantleUIView(_ view: DuoWindowProbe, coordinator: ()) {
        view.stop()
    }
}

/// Reads the actual UIWindow, so padding, keyboards, sheets and constrained root
/// content don't turn a view's dimensions into the reported window dimensions.
@available(iOS 27.1, *)
final class DuoWindowProbe: UIView {
    private let tracker: DuoTracker
    private(set) var foldState: DuoFoldState?
    private var thresholds: DuoFoldThresholds
    private var hingeAngle: Double?
    private var pendingUpdate: Task<Void, Never>?
    private var hingeInteraction: UIHingeInteraction?

    init(tracker: DuoTracker, thresholds: DuoFoldThresholds) {
        self.tracker = tracker
        self.thresholds = thresholds
        super.init(frame: .zero)
        isUserInteractionEnabled = false

        let interaction = UIHingeInteraction { [weak self] _, update in
            guard let self, let hinge = update.hinge else { return }
            // An unavailable reading can be transient when moving hierarchies.
            // Keep the last valid physical state until a fresh reading arrives.
            updateHingeAngle(Double(hinge.angle))
        }
        hingeInteraction = interaction
        addInteraction(interaction)

        registerForTraitChanges([
            UITraitHorizontalSizeClass.self,
            UITraitVerticalSizeClass.self,
            UITraitDisplayScale.self,
        ]) { (view: DuoWindowProbe, _: UITraitCollection) in
            view.setNeedsLayout()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(tracker:thresholds:)") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        NotificationCenter.default.removeObserver(self)
        if let scene = window?.windowScene {
            NotificationCenter.default.addObserver(
                self, selector: #selector(sceneDidActivate),
                name: UIScene.didActivateNotification, object: scene
            )
        }
        setNeedsLayout()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Query reserved regions during layout so UIKit can track dependencies.
        guard let window, let scene = window.windowScene, let foldState else { return }

        // Screen traits describe the display; window traits may be compact on
        // the inner display in Split View. Never infer display from hinge state.
        let screen = scene.screen
        guard let display = DuoConfiguration.display(
            horizontal: sizeClass(screen.traitCollection.horizontalSizeClass),
            vertical: sizeClass(screen.traitCollection.verticalSizeClass)
        ) else { return }
        let frameOnScreen = window.convert(window.bounds, to: screen.coordinateSpace)
        guard let configuration = DuoConfiguration(
            windowSize: window.bounds.size,
            display: display,
            foldState: foldState,
            isFullScreen: DuoConfiguration.fillsDisplay(
                windowFrame: frameOnScreen,
                displayBounds: screen.coordinateSpace.bounds,
                scale: screen.scale
            ),
            widthClass: sizeClass(window.traitCollection.horizontalSizeClass),
            hasActiveDivision: !window.reservedRegions(kind: .division).isEmpty
        ) else { return }

        // Deliver outside UIKit/SwiftUI's layout pass. Coalesce pending samples
        // and reject a sample if the probe has since moved to another window.
        pendingUpdate?.cancel()
        let windowID = ObjectIdentifier(window)
        pendingUpdate = Task { @MainActor [weak self] in
            guard !Task.isCancelled, let self,
                  let currentWindow = self.window,
                  ObjectIdentifier(currentWindow) == windowID else { return }
            tracker.update(configuration, windowID: windowID)
            pendingUpdate = nil
        }
    }

    @objc private func sceneDidActivate() { setNeedsLayout() }

    func updateThresholds(_ thresholds: DuoFoldThresholds) {
        guard thresholds != self.thresholds else { return }
        self.thresholds = thresholds
        if let hingeAngle { updateHingeAngle(hingeAngle) }
    }

    func updateHingeAngle(_ angle: Double) {
        guard let newState = DuoFoldState(hingeAngle: angle, thresholds: thresholds) else { return }
        // Retain the newest reading even within the same classification, so
        // changing thresholds can immediately reclassify the physical pose.
        hingeAngle = angle
        guard newState != foldState else { return }
        foldState = newState
        setNeedsLayout()
    }

    private func sizeClass(_ value: UIUserInterfaceSizeClass) -> DuoConfiguration.SizeClass {
        switch value {
        case .compact: .compact
        case .regular: .regular
        default: .unspecified
        }
    }

    func stop() {
        pendingUpdate?.cancel()
        pendingUpdate = nil
        hingeInteraction?.isEnabled = false
        NotificationCenter.default.removeObserver(self)
    }
}
#endif
