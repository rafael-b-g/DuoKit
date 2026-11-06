import Testing
@testable import DuoKit

struct DuoFoldStateTests {
    @Test(arguments: [0.0, 0.5, 1.0])
    func closedEndpointToleratesSmallVariations(degrees: Double) {
        #expect(DuoFoldState(hingeAngle: degrees * .pi / 180) == .closed)
    }

    @Test(arguments: [179.0, 179.5, 180.0])
    func fullyOpenEndpointToleratesSmallVariations(degrees: Double) {
        #expect(DuoFoldState(hingeAngle: degrees * .pi / 180) == .fullyOpen)
    }

    @Test(arguments: [1.01, 13.579383850097656, 16.1928, 50.4308, 90.0, 178.99])
    func openingsBetweenEndpointsArePartiallyOpen(degrees: Double) {
        // Includes actual tent-pose readings whose native status was closed.
        #expect(DuoFoldState(hingeAngle: degrees * .pi / 180) == .partiallyOpen)
    }

    @Test(arguments: [Double.nan, .infinity, -.infinity])
    func nonfiniteAnglesAreUnavailable(angle: Double) {
        #expect(DuoFoldState(hingeAngle: angle) == nil)
    }

    @Test func smallEndpointOvershootsStayAtTheEndpoint() {
        #expect(DuoFoldState(hingeAngle: -0.001) == .closed)
        #expect(DuoFoldState(hingeAngle: .pi + 0.001) == .fullyOpen)
    }
}
