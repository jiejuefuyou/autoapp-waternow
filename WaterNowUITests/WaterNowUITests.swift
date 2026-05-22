import XCTest

/// Apple Review 2026-05-22 v1.0.1 build 7 (2.3.3, WaterNow): reviewer
/// rejected because 6.5" iPhone screenshots "do not show the actual app
/// in use" (PIL-synthetic marketing collateral, per CLAUDE.md lesson #44).
///
/// This fastlane snapshot UI test captures the real running app on the
/// simulator across 5 core screens × 8 locales × 3 device sizes, all in
/// CI. The output is uploaded to ASC via the orchestrator step in the
/// parent task (out of scope here).
final class WaterNowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    @MainActor
    func testScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += [
            "-FASTLANE_SNAPSHOT", "YES",
            "-ui_testing",
            // Hint to the app that it should bypass onboarding and seed
            // a few entries so the home screen looks "in use" — caught
            // by AppLaunchOptions read in WaterNowApp / HydrationStore.
            "-uitest_seed_data", "YES",
            "-uitest_skip_onboarding", "YES",
        ]
        app.launch()

        // Give SwiftUI a moment to settle after the bundle-swizzle locale init
        // (LocalizationManager.installBundleOverride runs in App.init).
        sleep(2)

        // 01 — Home (progress ring + cup grid + quick add row)
        //      This is the "core concept" screen reviewers look for.
        snapshot("01-Home")

        // 02 — Log a few cups so the progress ring fills + streak shows.
        //      Tap medium-sized "M" (250 ml) twice to make the ring visibly fill.
        let mediumButton = app.buttons.matching(identifier: "Add 250 milliliters").firstMatch
        if mediumButton.waitForExistence(timeout: 5) {
            mediumButton.tap()
            sleep(1)
            mediumButton.tap()
            sleep(1)
        } else {
            // Fallback: tap any quick-add row button that contains "250 ml" label.
            let quickMatch = app.staticTexts["250 ml"].firstMatch
            if quickMatch.waitForExistence(timeout: 3) {
                quickMatch.tap()
                sleep(1)
            }
        }
        // Also tap large to show variety in beverage logging.
        let largeButton = app.buttons.matching(identifier: "Add 500 milliliters").firstMatch
        if largeButton.exists {
            largeButton.tap()
            sleep(1)
        }
        snapshot("02-HomeWithProgress")

        // 03 — Settings (Daily Goal + Language picker + Reminder section)
        let settingsButton = app.buttons["Settings"].firstMatch
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            sleep(2)
            snapshot("03-Settings")

            // Close the sheet.
            let closeButtons = app.buttons.matching(NSPredicate(format: "label IN %@", ["Done", "Close", "完了", "完成", "完了", "Fertig", "Hecho", "OK", "닫기"]))
            if closeButtons.count > 0 {
                closeButtons.firstMatch.tap()
                sleep(1)
            } else {
                // Swipe down to dismiss as a fallback.
                app.swipeDown(velocity: .fast)
                sleep(1)
            }
        }

        // 04 — Paywall (clear shows IAP screen with feature list + price button)
        let proButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Pro'")).firstMatch
        if proButton.waitForExistence(timeout: 5) {
            proButton.tap()
            sleep(2)
            snapshot("04-Paywall")

            // Close paywall.
            let closeAgain = app.buttons.matching(NSPredicate(format: "label IN %@", ["Close", "閉じる", "关闭", "關閉", "Cerrar", "Fermer", "Schließen", "닫기"]))
            if closeAgain.count > 0 {
                closeAgain.firstMatch.tap()
                sleep(1)
            } else {
                app.swipeDown(velocity: .fast)
                sleep(1)
            }
        }

        // 05 — Quick add menu / beverage picker (alternate hero shot showcasing variety)
        //      Just leave the home screen with progress + take another shot
        //      framing the beverage picker open.
        let beveragePicker = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Water' OR label CONTAINS[c] 'Beverage'")).firstMatch
        if beveragePicker.waitForExistence(timeout: 3) {
            beveragePicker.tap()
            sleep(1)
            snapshot("05-BeveragePicker")
            // Dismiss menu.
            app.tap()
            sleep(1)
        } else {
            // Final fallback: just snapshot the populated home a second time.
            snapshot("05-HomeFinal")
        }
    }
}
