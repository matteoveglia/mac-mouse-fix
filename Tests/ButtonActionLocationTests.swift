import CoreGraphics

@main
struct ButtonActionLocationTests {
    static func main() {
        var location = ButtonActionLocation()

        location.recordPress(at: CGPoint(x: 14, y: 27))
        precondition(location.point == CGPoint(x: 14, y: 27),
                     "a deferred action must retain its physical press point")

        location.recordPress(at: CGPoint(x: 80, y: 35))
        precondition(location.point == CGPoint(x: 80, y: 35),
                     "a repeated press must replace the preceding click level's point")

        print("ButtonActionLocationTests passed")
    }
}
