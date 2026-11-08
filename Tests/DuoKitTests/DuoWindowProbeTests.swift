#if os(iOS) && !targetEnvironment(macCatalyst)
import Testing
@testable import DuoKit

@MainActor
struct DuoWindowProbeTests {
    @Test
    @available(iOS 27.1, *)
    func newThresholdsReclassifyLatestAngleWithoutHingeMovement() {
        let probe = DuoWindowProbe(tracker: DuoTracker(), thresholds: DuoFoldThresholds())
        defer { probe.stop() }
        probe.updateHingeAngle(12 * .pi / 180)
        probe.updateHingeAngle(20 * .pi / 180)
        #expect(probe.foldState == .partiallyOpen)

        // Both readings were partially open; reclassification must use 20°.
        probe.updateThresholds(DuoFoldThresholds(closed: 15 * .pi / 180))
        #expect(probe.foldState == .partiallyOpen)
        probe.updateThresholds(DuoFoldThresholds(closed: 25 * .pi / 180))
        #expect(probe.foldState == .closed)

        // An unavailable reading must not replace the last valid angle.
        probe.updateHingeAngle(.nan)
        probe.updateThresholds(DuoFoldThresholds())
        #expect(probe.foldState == .partiallyOpen)
    }

    @Test
    @available(iOS 27.1, *)
    func thresholdUpdateBeforeFirstReadingDoesNotInventAState() {
        let probe = DuoWindowProbe(tracker: DuoTracker(), thresholds: DuoFoldThresholds())
        defer { probe.stop() }
        probe.updateThresholds(DuoFoldThresholds(closed: 10 * .pi / 180))
        #expect(probe.foldState == nil)
        probe.updateHingeAngle(5 * .pi / 180)
        #expect(probe.foldState == .closed)
    }
}
#endif
