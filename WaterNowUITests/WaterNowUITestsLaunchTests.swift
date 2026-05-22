import XCTest

/// Minimal smoke launch test that runs in CI before the snapshot lane.
/// Verifies the app can cold-launch without crashing in the simulator —
/// without this, fastlane snapshot will silently produce 0-byte PNGs on
/// a binary that fails to launch.
final class WaterNowUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
