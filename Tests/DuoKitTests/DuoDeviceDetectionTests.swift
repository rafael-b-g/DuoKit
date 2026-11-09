import Testing
@testable import DuoKit

struct DuoDeviceDetectionTests {
    @Test func knownDuoIdentifierMatches() {
        #expect(DuoDeviceDetection.isKnownDuo(modelIdentifier: "iPhone19,4"))
    }

    @Test(arguments: ["", "arm64", "iPhone19,1", "iPhone99,1", "iPad99,1"])
    func otherIdentifiersRequireHingeFallback(identifier: String) {
        #expect(DuoDeviceDetection.isKnownDuo(modelIdentifier: identifier) == false)
    }
}
