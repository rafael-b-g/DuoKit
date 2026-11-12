# DuoKit

A SwiftUI package for adapting your app to the iPhone Duo.

DuoKit is most useful when you want to build custom interactions and designs specifically for the iPhone Duo. Apple recomends building apps that are flexible and adaptable to any screen size, orientation, and pose. But if you want to make something more custom for the iPhone Duo (or if you want a simpler way to work with Duo-specific APIs), DuoKit might be a good fit.

## Requirements & installation

- Xcode 27.2 / Swift 6.4 or later
- iOS 17 or later

In Xcode, add `https://github.com/rafael-b-g/DuoKit` as a Swift package dependency and link the **DuoKit** product.

## Quick start

Apply `.duoTracking()` once to the root view of each window:

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

Read the model from the environment:

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

You can also match broader cases such as `.phone`, `.pad`, or `.pad(_, .folded)`. Read only the properties your view needs. Each property is independently observable.

## Available information

| Property | Meaning | Possible values |
| --- | --- | --- |
| `layout` | The interface layout available to the window. | `.phone(.portrait)`<br>`.phone(.landscape)`<br>`.pad(.portrait, .flat)`<br>`.pad(.landscape, .flat)`<br>`.pad(.portrait, .folded)`<br>`.pad(.landscape, .folded)`<br>`.unknown` |
| `windowAspect` | Window proportions based on actual dimensions. Square windows use portrait. | `.portrait`<br>`.landscape`<br>`nil` |
| `display` | The physical display hosting the window. | `.inner`<br>`.outer`<br>`nil` |
| `foldState` | The hinge state derived from its measured angle. | `.closed`<br>`.partiallyOpen`<br>`.fullyOpen`<br>`nil` |
| `isFullScreen` | Whether the window fills the display. | `true`<br>`false`<br>`nil` |

The model stays stable as its window resizes, rotates, folds, or changes displays. Properties are read-only and update automatically.

## Understanding the state

- **`layout` does not indicate physical display.** Windows in Split View on the inner display use `.phone`, just like windows in the outer display. If you need to know the actual display your window is in, use the `display` property.
- **Folded layout and hinge state are independent.** A pad layout becomes `.folded` when an active system division region intersects the app window. A partially open hinge alone does not imply a folded layout, and the outer display can be active while the hinge is partially open (for example, when the Duo is in a "tent" pose).
- **Aspect describes window proportions.** It does not indicate physical device orientation (the user can lock orientation, and your app might not occupy the entire screen, like in Split View). Padding and the keyboard do not affect it.
- **Handle pending values.** `duo != nil` means Duo hardware was detected. Its layout starts as `.unknown`. Other properties start as `nil` and become available independently. Temporary missing readings retain the last valid values.

## Configuration

By default, `foldState` is `.closed` at hinge angles at or below 1°, `.fullyOpen` at or above 179°, and `.partiallyOpen` between those thresholds.

You can customize these thresholds:

```swift
ContentView()
    .duoTracking(
        closedThreshold: .degrees(5),
        fullyOpenThreshold: .degrees(175)
    )
```

Thresholds must be finite and satisfy `0° ≤ closedThreshold < fullyOpenThreshold ≤ 180°`; invalid values fail a precondition. Changes immediately reclassify the latest valid hinge reading.

## Support & limitations

- On unsupported devices, iOS versions before 27.1, and Mac Catalyst, `duo` is `nil`.
- Display identification is inferred from the screen's size classes because the SDK has no explicit inner/outer identifier.

## Contributing & license

Feel free to open an issue if you find any bugs or have any suggestions/feedback.

Released under the [MIT License](LICENSE).
