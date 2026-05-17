---
id: waternow
title: WaterNow (iOS) - Hydration tracker
category: new-ios-app
priority: P2
status: in-development
revenue_usd_month: "14-696"
actions: [open-editor, run-script]
tags: [ios, swiftui, storekit2, health, hydration]
ice_score: 4.48
tier_price_usd: 1.99
created: 2026-05-06
---
# WaterNow (iOS)

Hydration tracker for iPhone + iPad. Log water / tea / coffee / juice intake against a daily goal with progress ring + 7-day history (free) or full history + reminders + Live Activity (Pro).

## Status

**v0.1.0 in-development** (2026-05-17, Tick #210). Swift skeleton ready, CI/fastlane bootstrap complete, awaiting first TestFlight build.

## Architecture

- **iOS 17+ SwiftUI** (`@Observable` + Observation framework)
- **StoreKit 2** for IAP (one-time $1.99 Pro unlock)
- **UserDefaults** for persistence (zero backend, zero sync)
- **No HealthKit in v1.0** (planned for v1.1 Pro)
- **No external dependencies** (no SPM, no CocoaPods)

## File structure

```
WaterNow/
├── App/WaterNowApp.swift          # @main + state injection (IAPManager + HydrationStore)
├── IAP/IAPManager.swift           # StoreKit 2 wrapper (~90 LOC)
├── Models/Hydration.swift         # HydrationEntry + BeverageType + CupSize
├── Services/HydrationStore.swift  # @Observable + UserDefaults persist
└── Views/
    ├── ContentView.swift          # Progress ring + cup buttons + beverage picker
    ├── OnboardingView.swift       # First-launch goal pick + Skip
    ├── PaywallView.swift          # IAP unlock UI (PurchaseState enum + alert)
    └── SettingsView.swift         # Daily goal / Premium / About / Language picker
```

## Free vs Pro

```
Free tier:
  - Daily total tracking with progress ring
  - 4 cup sizes (sip 100 ml / glass 250 ml / bottle 500 ml / large bottle 1 L)
  - 6 beverage types (water / tea / coffee / juice / sparkling / other)
  - 7-day history visible
  - System unit preferences

Pro ($1.99 one-time, com.jiejuefuyou.waternow.premium):
  - Full history (any timeframe)
  - Lock screen widget                  (planned v1.1)
  - Live Activity (Dynamic Island)      (planned v1.1)
  - Apple Watch complication            (planned v1.2)
  - Custom hydration reminders          (planned v1.1)
  - Weekly + monthly insights
  - Custom themes + cup sizes
  - CSV export                          (planned v1.1)
```

## Build steps (local)

```bash
# 1. Generate Xcode project
brew install xcodegen
cd repos/autoapp-waternow
xcodegen generate

# 2. Open in Xcode
open WaterNow.xcodeproj

# 3. Set development team in Xcode signing
# 4. Build to simulator / device
# 5. Test sandbox IAP with test account
```

## CI / TestFlight (`git push tag v*`)

```bash
# Cuts a TestFlight build automatically (macos-15 runner)
git tag v0.1.0
git push origin v0.1.0
# → .github/workflows/testflight.yml triggers fastlane beta lane
```

## ASC setup

```
Bundle ID: com.jiejuefuyou.waternow
Product ID: com.jiejuefuyou.waternow.premium
SKU: waternow-ios-001
Type: Non-Consumable
Price: $1.99 (Tier 2 — ¥300 JPY)
Category: Health & Fitness
```

## Roadmap

| Week | Milestone |
|---|---|
| W1 | v0.1.0 — scaffold + IAP + ContentView (this) |
| W2 | v1.0.0 — Onboarding + Settings + Privacy + first TF build |
| W3 | v1.0.1 — 8 lang i18n (en/ja/zh-Hans/zh-Hant/ko/es/fr/de) |
| W4 | v1.0.2 — App Store submit |
| W5 | v1.1.0 — Local reminders + Live Activity + Lock screen widget |
| W6 | v1.1.1 — CSV export + HealthKit opt-in write |
| W7 | v1.2.0 — Apple Watch complication |
| W8 | v1.2.1 — Polish + content launch |

## Day 30 ROI projection

```
DAU 200 (organic + niche health communities)
Conv 5% × $1.99 × 0.7 (after Apple) = $14/month

DAU 1000 (TikTok 健康 / Reddit r/hydrohomies hit)
Conv 8% × $1.99 × 0.7 = $111/month

DAU 5000 (1 viral + ASO long tail)
Conv 10% × $1.99 × 0.7 = $696/month
```

## Marketing positioning

- **ICP 1**: Office workers tracking water at desk (US / EU)
- **ICP 2**: Gym / fitness enthusiasts (US / JP)
- **ICP 3**: Pregnancy / nursing mothers (hydration-critical)
- **ICP 4**: Elderly users with kidney concerns (need quantified intake)
- **ICP 5**: Diet / weight loss users (water-first habit stack)

## Known limitations (v1.0)

- No HealthKit (planned v1.1 Pro)
- No Live Activity / Dynamic Island (planned v1.1 Pro)
- No widget (planned v1.1 Pro)
- No Apple Watch target (planned v1.2 Pro)
- No backend (UserDefaults only, OK for v1; potential CloudKit sync v2.0)
- No cross-device sync

## License

MIT (subject to change). Pattern reused from autoapp-tipjar-now / autoapp-altitude-now / autoapp-days-until / autoapp-prompt-vault.

## Contact

Issues: https://github.com/jiejuefuyou/autoapp-waternow/issues
Email: jiejuefuyou@gmail.com
Support page: https://jiejuefuyou.github.io/support-waternow.html
