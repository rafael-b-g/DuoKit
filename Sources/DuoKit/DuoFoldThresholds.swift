/// Validated radians used by the hinge callback, without per-reading validation
/// of configuration or conversion between angle units.
struct DuoFoldThresholds: Equatable, Sendable {
    let closed: Double
    let fullyOpen: Double

    init(closed: Double = .pi / 180, fullyOpen: Double = .pi - .pi / 180) {
        precondition(
            closed.isFinite && fullyOpen.isFinite
                && closed >= 0 && closed < fullyOpen && fullyOpen <= .pi,
            "Fold thresholds must satisfy 0° ≤ closedThreshold < fullyOpenThreshold ≤ 180°."
        )
        self.closed = closed
        self.fullyOpen = fullyOpen
    }
}
