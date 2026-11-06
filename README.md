# DuoKit

A small SwiftUI package for adapting interfaces to iPhone Duo. One observable
model per window exposes layout, window proportions, display, hinge state, and
full-screen occupancy. No dependencies, polling, or app-delegate setup.

## Requirements

- Xcode 27.2 / Swift 6.4 or later.
- iOS 17 or later to import the package; live Duo tracking requires iOS 27.1.
- On earlier iOS versions, ordinary iPhones, iPads, and Mac Catalyst,
  the environment value is `nil`.

Add this repository as a Swift package dependency and link the **DuoKit** product.

## Setup

Apply tracking once to the root of each window:

```swift
import SwiftUI
import DuoKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .duoTracking()
        }
    }
}
```

Read only the properties your view needs:

```swift
struct ContentView: View {
    @Environment(\.duo) private var duo

    var body: some View {
        switch duo?.layout {
        case .phone(.portrait):
            Text("Phone portrait")
        case .phone(.landscape):
            Text("Phone landscape")
        case .pad(.portrait, .flat):
            Text("Pad portrait")
        case .pad(.landscape, .flat):
            Text("Pad landscape")
        case .pad(.portrait, .folded):
            Text("Folded portrait")
        case .pad(.landscape, .folded):
            Text("Folded landscape")
        case .unknown, nil:
            Text("Default layout")
        }
    }
}
```

Broader patterns such as `.phone`, `.pad`, and `.pad(_, .folded)` also work.
`duo?.windowAspect`, `duo?.display`, `duo?.foldState`, and `duo?.isFullScreen`
are independently observable; pattern matching is optional.

## Semantics

| Property | Meaning |
| --- | --- |
| `layout` | Outer display or compact-width inner window → `.phone`. Regular-width inner window → `.pad`. An active division region in that window selects `.folded`; otherwise `.flat`. |
| `windowAspect` | Width greater than height → `.landscape`; otherwise `.portrait`. A square window uses `.portrait`. Reads the actual window, unaffected by content padding or the keyboard. |
| `display` | The physical screen hosting this window, independently of the window's own size class and the hinge state. |
| `foldState` | Derived from the measured hinge angle: ≤ 1° → `.closed`, ≥ 179° → `.fullyOpen`, otherwise `.partiallyOpen`. Independent of the active display and system hinge status. |
| `isFullScreen` | The window covers its display in screen coordinates, within one physical pixel. Split View and space occupied by pinned video make this `false`. |

Aspect never determines fold direction. A partially open hinge does not itself
make the layout `.folded`: only an active division region intersecting the app
window does. A compact inner-display Split View window remains `.phone` even
while the hinge is partially open. A wide window below pinned video can remain
`.pad` while `isFullScreen` is `false`.

In a tent pose, an app on the outer display reports `.phone(windowAspect)`,
`display == .outer`, and `foldState == .partiallyOpen`. Showing the outer display
does not imply that the hinge is closed. Openings within the 1° endpoint
tolerance count as closed. Hinge changes update `foldState` even
when the display, layout, and window dimensions remain unchanged.

The optional environment value starts as `nil` until a valid window, display,
and hinge sample arrive, and remains `nil` on unsupported devices. The same
`Duo` object is then updated throughout that window's lifetime. Temporary
unavailable or nonfinite hinge readings, or zero-sized geometry, retain the last
valid values.

`.unknown` is retained for a specific case: a recognized inner-display window
has usable geometry but its horizontal size class is unspecified. This avoids
guessing a phone or pad layout and keeps the other properties available. It is
different from `nil`, which means no tracked Duo model is available.

## Implementation

`Duo` is `@MainActor` and `@Observable`, with independently stored, read-only
public properties. Updates change only unequal properties. Reading `layout`
does not subscribe a view to unrelated physical hinge changes, and the
environment object is not replaced on each update.

A small, noninteractive UIKit view reads its containing `UIWindow` and scene.
It uses native hinge callbacks, reserved regions, layout and trait changes, and
scene activation. Samples are delivered outside the layout pass and pending
samples are coalesced. Each `.duoTracking()` installation owns its model; there
is no shared singleton or search through global windows.

Each angle callback performs a finite-value check and at most two endpoint
comparisons. An unchanged fold classification returns immediately, without
scheduling layout or an observable model update. The 1° tolerance is DuoKit's
classification policy, rather than a claim about sensor precision; it keeps
small endpoint variations in the same state. Layout still follows active
division regions independently.

**Display identification:** the public SDK does not expose an inner/outer
display identifier. After hinge detection, DuoKit infers it from the hosting
**screen's** size classes: regular on both axes means inner; a compact axis
means outer. It does not use the app window's size classes for this inference.
The distinction matters in Split View and when the outer display rotates.
This mapping is verified on the iOS 27.2 iPhone Duo simulator and should be
rechecked when supporting new hardware or SDK behavior.

The public enums are `Hashable` and `Sendable`. Model creation and mutation are
internal; apps access their scene's model through the environment.

## Validation

```sh
xcodebuild -scheme DuoKit -destination 'platform=iOS Simulator,name=iPhone 17' test
xcodebuild -scheme DuoKit -destination 'generic/platform=iOS Simulator' build
```

Unit tests run on an iOS simulator. Substitute the name of an installed iOS
simulator if needed; the unit tests do not require Duo hardware.

Tests cover all six layouts, Split View, pinned-video sizing, independent hinge
and layout state, missing geometry, display inference, full-screen geometry,
per-window identity, and property-level observation.

Live checks on the iOS 27.2 iPhone Duo simulator cover all six layouts, stable
model identity through display changes and rotation, and two simultaneous
Split View windows with distinct models. Both Split View windows report
`.phone(.portrait)`, `.inner`, and `isFullScreen == false`. Folding and
unfolding also update layout when the window's dimensions stay unchanged.
These are simulator checks, not physical-device validation.

References: [Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/),
[adaptive layouts and reserved regions](https://developer.apple.com/videos/play/tech-talks/111463/),
and [hinge information and multiple scenes](https://developer.apple.com/videos/play/tech-talks/111464/).
