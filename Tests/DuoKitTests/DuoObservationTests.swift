import Foundation
import Observation
import SwiftUI
import Testing
@testable import DuoKit

@MainActor
struct DuoObservationTests {
    @Test func environmentDefaultsToNil() {
        #expect(EnvironmentValues().duo == nil)
    }

    @Test(arguments: [Aspect.portrait, .landscape])
    func tentPoseUpdatesHingeWhileOuterPhoneLayoutStaysTheSame(aspect: Aspect) async throws {
        let size = aspect == .portrait
            ? CGSize(width: 400, height: 800)
            : CGSize(width: 800, height: 400)
        let closed = try #require(DuoConfiguration(
            windowSize: size, display: .outer, foldState: .closed,
            isFullScreen: true, widthClass: .compact, hasActiveDivision: false
        ))
        // This measured angle had a native `.closed` status in the simulator.
        let physicalState = try #require(DuoFoldState(hingeAngle: 0.2370049585763482))
        let tent = try #require(DuoConfiguration(
            windowSize: size, display: .outer, foldState: physicalState,
            isFullScreen: true, widthClass: .compact, hasActiveDivision: false
        ))
        let duo = Duo(closed)

        await confirmation { changed in
            withObservationTracking {
                _ = duo.foldState
            } onChange: {
                changed()
            }
            duo.update(tent)
        }

        #expect(duo.layout == .phone(aspect))
        #expect(duo.display == .outer)
        #expect(duo.foldState == .partiallyOpen)
        #expect(duo.isFullScreen)
    }

    @Test func windowsOwnIndependentInstances() throws {
        let firstTracker = DuoTracker()
        let secondTracker = DuoTracker()
        let firstWindow = NSObject()
        let secondWindow = NSObject()
        firstTracker.update(configuration(), windowID: ObjectIdentifier(firstWindow))
        secondTracker.update(configuration(), windowID: ObjectIdentifier(secondWindow))

        let first = try #require(firstTracker.duo)
        let second = try #require(secondTracker.duo)
        #expect(first !== second)
        firstTracker.update(configuration(folded: true), windowID: ObjectIdentifier(firstWindow))
        #expect(firstTracker.duo === first)
        #expect(first.layout == .pad(.portrait, .folded))
        #expect(second.layout == .pad(.portrait, .flat))

        firstTracker.update(configuration(), windowID: ObjectIdentifier(secondWindow))
        #expect(firstTracker.duo !== first)
    }

    @Test func unrelatedPropertiesDoNotInvalidateLayoutReaders() async {
        let duo = Duo(configuration())
        await confirmation(expectedCount: 0) { changed in
            withObservationTracking {
                _ = duo.layout
                _ = duo.windowAspect
                _ = duo.display
                _ = duo.isFullScreen
            } onChange: {
                changed()
            }
            duo.update(configuration(hinge: .partiallyOpen))
            #expect(duo.foldState == .partiallyOpen)
        }
    }

    @Test func identicalSamplesDoNotNotify() async {
        let duo = Duo(configuration())
        await confirmation(expectedCount: 0) { changed in
            withObservationTracking {
                _ = duo.layout
                _ = duo.windowAspect
                _ = duo.display
                _ = duo.foldState
                _ = duo.isFullScreen
            } onChange: {
                changed()
            }
            duo.update(configuration())
        }
    }

    @Test func layoutChangesNotifyTheirReaders() async {
        let duo = Duo(configuration())
        await confirmation { changed in
            withObservationTracking {
                _ = duo.layout
            } onChange: {
                changed()
            }
            duo.update(configuration(folded: true))
        }
        #expect(duo.layout == .pad(.portrait, .folded))
    }

    @Test func updatesDoNotReplaceEnvironmentModel() async throws {
        let tracker = DuoTracker()
        let window = NSObject()
        tracker.update(configuration(), windowID: ObjectIdentifier(window))
        let initial = try #require(tracker.duo)
        await confirmation(expectedCount: 0) { changed in
            withObservationTracking {
                _ = tracker.duo
            } onChange: {
                changed()
            }
            tracker.update(configuration(folded: true), windowID: ObjectIdentifier(window))
        }
        #expect(tracker.duo === initial)
        #expect(initial.layout == .pad(.portrait, .folded))
    }

    private func configuration(
        hinge: DuoFoldState = .fullyOpen,
        folded: Bool = false
    ) -> DuoConfiguration {
        // The fixed, positive test dimensions always form a valid sample.
        DuoConfiguration(
            windowSize: CGSize(width: 700, height: 900), display: .inner,
            foldState: hinge, isFullScreen: true, widthClass: .regular,
            hasActiveDivision: folded
        )!
    }
}
