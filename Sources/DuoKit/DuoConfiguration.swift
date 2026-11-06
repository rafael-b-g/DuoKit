import Foundation

/// A normalized system sample. No raw hinge angles enter layout classification.
struct DuoConfiguration: Equatable {
    enum SizeClass {
        case compact, regular, unspecified
    }

    let aspect: Aspect
    let display: DuoDisplay
    let foldState: DuoFoldState
    let isFullScreen: Bool
    let layout: DuoLayout

    init?(
        windowSize: CGSize,
        display: DuoDisplay,
        foldState: DuoFoldState,
        isFullScreen: Bool,
        widthClass: SizeClass,
        hasActiveDivision: Bool
    ) {
        guard windowSize.width.isFinite, windowSize.height.isFinite,
              windowSize.width > 0, windowSize.height > 0 else { return nil }

        // A square window uses portrait as a deterministic tie-breaker.
        aspect = windowSize.width > windowSize.height ? .landscape : .portrait
        self.display = display
        self.foldState = foldState
        self.isFullScreen = isFullScreen

        switch (display, widthClass) {
        case (.outer, _), (.inner, .compact):
            layout = .phone(aspect)
        case (.inner, .regular):
            layout = .pad(aspect, hasActiveDivision ? .folded : .flat)
        case (.inner, .unspecified):
            layout = .unknown
        }
    }

    /// The built-in inner display is regular on both axes. The outer display
    /// has a compact axis, including compact height when rotated to landscape.
    /// These must be screen traits, not the smaller app window's traits.
    static func display(horizontal: SizeClass, vertical: SizeClass) -> DuoDisplay? {
        switch (horizontal, vertical) {
        case (.regular, .regular): .inner
        case (.compact, _), (_, .compact): .outer
        default: nil
        }
    }

    /// Rectangles must be in the same screen coordinate space, including origins.
    static func fillsDisplay(windowFrame: CGRect, displayBounds: CGRect, scale: CGFloat) -> Bool {
        guard scale.isFinite, scale > 0,
              windowFrame.width > 0, windowFrame.height > 0,
              displayBounds.width > 0, displayBounds.height > 0 else { return false }
        let tolerance = 1 / scale
        return abs(windowFrame.minX - displayBounds.minX) <= tolerance
            && abs(windowFrame.minY - displayBounds.minY) <= tolerance
            && abs(windowFrame.maxX - displayBounds.maxX) <= tolerance
            && abs(windowFrame.maxY - displayBounds.maxY) <= tolerance
    }
}
