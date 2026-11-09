import Foundation
import Testing
@testable import DuoKit

struct DuoConfigurationTests {
    @Test func geometryIsAvailableBeforeDisplayAndHinge() throws {
        let configuration = try #require(DuoConfiguration(
            windowSize: CGSize(width: 700, height: 900),
            isFullScreen: true, widthClass: .regular, hasActiveDivision: false
        ))
        #expect(configuration.aspect == .portrait)
        #expect(configuration.isFullScreen)
        #expect(configuration.layout == .unknown)
        #expect(configuration.display == nil)
        #expect(configuration.foldState == nil)
    }

    @Test func physicalDisplayUsesBothScreenSizeClasses() {
        #expect(DuoConfiguration.display(horizontal: .compact, vertical: .regular) == .outer)
        #expect(DuoConfiguration.display(horizontal: .regular, vertical: .compact) == .outer)
        #expect(DuoConfiguration.display(horizontal: .regular, vertical: .regular) == .inner)
        #expect(DuoConfiguration.display(horizontal: .unspecified, vertical: .regular) == nil)
    }

    @Test(arguments: [Aspect.portrait, .landscape])
    func allSixLayouts(aspect: Aspect) throws {
        let size = size(for: aspect)
        let phone = try #require(DuoConfiguration(
            windowSize: size, display: .outer, foldState: .closed,
            isFullScreen: true, widthClass: .compact, hasActiveDivision: false
        ))
        let flat = try #require(DuoConfiguration(
            windowSize: size, display: .inner, foldState: .fullyOpen,
            isFullScreen: true, widthClass: .regular, hasActiveDivision: false
        ))
        let folded = try #require(DuoConfiguration(
            windowSize: size, display: .inner, foldState: .partiallyOpen,
            isFullScreen: true, widthClass: .regular, hasActiveDivision: true
        ))
        #expect(phone.layout == .phone(aspect))
        #expect(flat.layout == .pad(aspect, .flat))
        #expect(folded.layout == .pad(aspect, .folded))
        #expect(phone.aspect == aspect)
        #expect(flat.aspect == aspect)
        #expect(folded.aspect == aspect)
    }

    @Test(arguments: [Aspect.portrait, .landscape], [DuoFoldState.closed, .partiallyOpen, .fullyOpen])
    func compactInnerWindowIsPhone(aspect: Aspect, hinge: DuoFoldState) throws {
        let configuration = try #require(DuoConfiguration(
            windowSize: size(for: aspect), display: .inner, foldState: hinge,
            isFullScreen: false, widthClass: .compact, hasActiveDivision: true
        ))
        #expect(configuration.layout == .phone(aspect))
        #expect(configuration.display == .inner)
        #expect(configuration.foldState == hinge)
        #expect(configuration.isFullScreen == false)
    }

    @Test(arguments: [DuoFoldState.closed, .partiallyOpen, .fullyOpen])
    func foldLayoutUsesActiveRegionRatherThanHinge(hinge: DuoFoldState) throws {
        let configuration = try #require(DuoConfiguration(
            windowSize: CGSize(width: 900, height: 700), display: .inner, foldState: hinge,
            isFullScreen: true, widthClass: .regular, hasActiveDivision: false
        ))
        #expect(configuration.layout == .pad(.landscape, .flat))
        #expect(configuration.foldState == hinge)
    }

    @Test func regularWindowBelowPinnedVideoRemainsPad() throws {
        let configuration = try #require(DuoConfiguration(
            windowSize: CGSize(width: 900, height: 350), display: .inner,
            foldState: .partiallyOpen, isFullScreen: false,
            widthClass: .regular, hasActiveDivision: false
        ))
        #expect(configuration.layout == .pad(.landscape, .flat))
        #expect(configuration.isFullScreen == false)
    }

    @Test func outerDisplayRemainsPhoneWhileOpen() throws {
        let configuration = try #require(DuoConfiguration(
            windowSize: CGSize(width: 400, height: 800), display: .outer,
            foldState: .fullyOpen, isFullScreen: true,
            widthClass: .regular, hasActiveDivision: true
        ))
        #expect(configuration.layout == .phone(.portrait))
        #expect(configuration.foldState == .fullyOpen)
        #expect(configuration.display == .outer)
    }

    @Test func unspecifiedInnerSizeClassHasUnknownLayout() throws {
        let configuration = try #require(DuoConfiguration(
            windowSize: CGSize(width: 800, height: 800), display: .inner,
            foldState: .fullyOpen, isFullScreen: true,
            widthClass: .unspecified, hasActiveDivision: false
        ))
        #expect(configuration.layout == .unknown)
        #expect(configuration.aspect == .portrait)
    }

    @Test(arguments: [
        CGSize.zero,
        CGSize(width: -1, height: 100),
        CGSize(width: 100, height: 0),
        CGSize(width: CGFloat.infinity, height: 100),
        CGSize(width: 100, height: CGFloat.nan),
    ])
    func unavailableGeometryDoesNotInventAnAspect(size: CGSize) {
        #expect(DuoConfiguration(
            windowSize: size, display: .inner, foldState: .fullyOpen,
            isFullScreen: true, widthClass: .regular, hasActiveDivision: false
        ) == nil)
    }

    @Test func fullScreenUsesPositionAndSizeWithPixelTolerance() {
        let bounds = CGRect(x: 0, y: 0, width: 900, height: 700)
        #expect(DuoConfiguration.fillsDisplay(windowFrame: bounds, displayBounds: bounds, scale: 3))
        #expect(DuoConfiguration.fillsDisplay(
            windowFrame: bounds.insetBy(dx: 0.2, dy: 0.2), displayBounds: bounds, scale: 3
        ))
        #expect(DuoConfiguration.fillsDisplay(
            windowFrame: bounds.offsetBy(dx: 10, dy: 0), displayBounds: bounds, scale: 3
        ) == false)
        #expect(DuoConfiguration.fillsDisplay(
            windowFrame: CGRect(x: 450, y: 0, width: 450, height: 700), displayBounds: bounds, scale: 3
        ) == false)
        #expect(DuoConfiguration.fillsDisplay(
            windowFrame: CGRect(x: 0, y: 350, width: 900, height: 350), displayBounds: bounds, scale: 3
        ) == false)
        #expect(DuoConfiguration.fillsDisplay(windowFrame: .zero, displayBounds: .zero, scale: 3) == false)
    }

    private func size(for aspect: Aspect) -> CGSize {
        aspect == .portrait ? CGSize(width: 700, height: 900) : CGSize(width: 900, height: 700)
    }
}
