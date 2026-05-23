import SwiftUI

/// Main hydration tracking screen.
///
/// v1.0.2 visual refresh (2026-05-21):
/// - Progress ring upgraded with aqua gradient + drop emoji + dynamic ml counter.
/// - 8-cup visualization grid (2×4) — each cup tappable to toggle filled/empty
///   for the canonical 250 ml glass goal. Long-press logs custom amounts.
/// - Quick Add row at the bottom (Small 100 / Medium 250 / Large 500 / XL 1000 ml).
/// - "+ Custom" button gated behind Pro (sheet -> Paywall when free).
/// - Streak counter pill in the top-right (consecutive days hitting goal).
/// - Mid-day reminder default 12:00 (Pro tier exposes the full 8-slot reminder list).
///
/// Layout still wraps in ScrollView (Apple Review iPad Guideline-4 fix from v1.0.1).
struct ContentView: View {
    @Environment(IAPManager.self) private var iap
    @Environment(HydrationStore.self) private var store
    @Environment(LocalizationManager.self) private var l10n

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showCustomAmount = false
    @State private var customAmountText: String = "250"
    @State private var selectedBeverage: BeverageType = .water

    // Default-glass size used for the 8-cup grid (one tap == one glass).
    private let glassML: Int = 250

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    progressRing

                    Text("/ \(store.dailyGoalML) ml")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Text(String(format: NSLocalizedString("%@ of daily goal", comment: "Percent label under hydration ring"),
                                "\(Int(store.todayPercent() * 100))%"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    cupGrid
                        .padding(.horizontal)

                    beveragePicker
                        .padding(.horizontal)

                    quickAddRow
                        .padding(.horizontal)
                }
                .padding()
                .padding(.bottom, 24)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(Text("WaterNow"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gear") }
                        .accessibilityLabel(Text("Settings"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        streakBadge
                        if !iap.isPremium {
                            Button { showPaywall = true } label: {
                                Label(LocalizedStringKey("Pro"), systemImage: "sparkles").font(.caption.bold())
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .tint(.accentColor)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(iap)
                    .environment(store)
                    .environment(l10n)
                    .environment(\.locale, l10n.currentLocale)
                    .id(l10n.override)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environment(iap)
                    .environment(l10n)
                    .environment(\.locale, l10n.currentLocale)
                    .id(l10n.override)
            }
            .sheet(isPresented: $showCustomAmount) {
                customAmountSheet
                    .environment(iap)
                    .environment(store)
                    .environment(l10n)
                    .environment(\.locale, l10n.currentLocale)
                    .id(l10n.override)
            }
            .task {
                await store.requestNotificationAuthorizationIfNeeded()
                store.ensureDefaultReminder()
            }
        }
    }

    // MARK: - Progress ring (TimelineView sine-wave fill — art-audit P0 2026-05-23)

    /// Hero hydration visual: a circular vessel whose water level reflects
    /// today's intake ratio, animated as a continuous sine wave (slow,
    /// non-distracting — amplitude 6pt, period ~5.2s, phase advances at 1.2 rad/s).
    /// The current ml value floats inside the ring at 64pt rounded-bold with
    /// `.contentTransition(.numericText())` so additions morph the digits.
    private var progressRing: some View {
        let ratio = max(0, min(1, store.todayPercent()))
        return ZStack {
            // Static background ring (vessel outline)
            Circle()
                .stroke(Color.secondary.opacity(0.18), lineWidth: 12)
                .frame(width: 200, height: 200)

            // Animated sine-wave fill clipped to the ring interior.
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                let phase = t * 1.2 / (2 * .pi)  // slow drift, ~0.19 Hz
                WaveShape(progress: ratio, phase: phase)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.31, green: 0.76, blue: 0.97).opacity(0.85),
                                Color(red: 0.012, green: 0.608, blue: 0.898).opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 188, height: 188)
                    .clipShape(Circle())
            }
            .frame(width: 188, height: 188)
            .animation(.easeInOut(duration: 0.45), value: ratio)

            // Floating 64pt ml counter — uses numericText content transition.
            VStack(spacing: 0) {
                Text("\(store.todayTotal())")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color(red: 0.012, green: 0.46, blue: 0.78))
                    .contentTransition(.numericText(value: Double(store.todayTotal())))
                    .shadow(color: .white.opacity(0.6), radius: 1, x: 0, y: 1)
                Text("ml")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .offset(y: -4)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(String(format: NSLocalizedString("%d milliliters today", comment: "Accessibility hero ml count"), store.todayTotal())))
        }
        .frame(width: 200, height: 200)
    }

    // MARK: - Streak badge

    private var streakBadge: some View {
        let streak = store.currentStreakDays()
        return HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(streak > 0 ? .orange : .secondary)
            Text("\(streak)")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(streak > 0 ? .primary : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityLabel(Text(String(format: NSLocalizedString("Streak %d days", comment: "Accessibility label for streak"), streak)))
    }

    // MARK: - 8 cup visualization

    /// Number of "default glasses" tapped today (rounded down) — used to drive
    /// the 8-cup grid fill state.
    private var glassesToday: Int {
        max(0, store.todayTotal() / glassML)
    }

    private var cupGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey("Cups today"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(0..<8, id: \.self) { idx in
                    cupButton(index: idx)
                }
            }
        }
    }

    private func cupButton(index: Int) -> some View {
        let filled = index < glassesToday
        return Button {
            // Tap toggles: tapping an unfilled slot logs +1 glass; tapping a filled slot removes most-recent glass-sized entry.
            if filled {
                store.removeLastEntryOfAmount(glassML)
            } else {
                store.add(glassML, beverage: selectedBeverage)
            }
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(filled ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.10))
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(filled ? Color.accentColor : Color.secondary.opacity(0.35), lineWidth: filled ? 2 : 1)
                    )
                Image(systemName: filled ? "drop.fill" : "drop")
                    .font(.title2)
                    .foregroundStyle(filled ? Color.accentColor : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)   // HIG hit target
        .accessibilityLabel(Text(filled
            ? String(format: NSLocalizedString("Cup %d, filled", comment: "Accessibility cup filled"), index + 1)
            : String(format: NSLocalizedString("Cup %d, empty, tap to log", comment: "Accessibility cup empty"), index + 1)))
    }

    // MARK: - Beverage picker

    private var beveragePicker: some View {
        Picker(LocalizedStringKey("Beverage"), selection: $selectedBeverage) {
            ForEach(BeverageType.allCases) { b in
                (Text("\(b.emoji) ") + Text(LocalizedStringKey(b.displayName)))
                    .tag(b)
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Add row

    private var quickAddRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey("Quick add"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                quickAddButton(title: "S", ml: 100)
                quickAddButton(title: "M", ml: 250)
                quickAddButton(title: "L", ml: 500)
                quickAddButton(title: "XL", ml: 1000)
                customAddButton
            }
        }
    }

    private func quickAddButton(title: LocalizedStringKey, ml: Int) -> some View {
        Button {
            store.add(ml, beverage: selectedBeverage)
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
        } label: {
            VStack(spacing: 2) {
                Text(title).font(.headline.bold())
                Text("\(ml) ml").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.35), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel(Text(String(format: NSLocalizedString("Add %d milliliters", comment: "Accessibility quick add"), ml)))
    }

    private var customAddButton: some View {
        Button {
            if iap.isPremium {
                showCustomAmount = true
            } else {
                showPaywall = true
            }
        } label: {
            VStack(spacing: 2) {
                if iap.isPremium {
                    Image(systemName: "plus")
                        .font(.headline.bold())
                } else {
                    Image(systemName: "lock.fill")
                        .font(.headline.bold())
                }
                Text(LocalizedStringKey("Custom"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.35), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel(Text(iap.isPremium
            ? NSLocalizedString("Add custom amount", comment: "Accessibility custom unlocked")
            : NSLocalizedString("Custom amount, Pro only", comment: "Accessibility custom locked")))
    }

    // MARK: - Custom amount sheet (Pro)

    private var customAmountSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("ml", text: $customAmountText)
                        .keyboardType(.numberPad)
                        .font(.title2.monospacedDigit())
                } header: {
                    Text(LocalizedStringKey("Amount in milliliters"))
                }
            }
            .navigationTitle(Text("Custom amount"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("Cancel")) { showCustomAmount = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("Add")) {
                        if let ml = Int(customAmountText.trimmingCharacters(in: .whitespaces)),
                           ml > 0, ml < 10_000 {
                            store.add(ml, beverage: selectedBeverage)
                            customAmountText = "250"
                            showCustomAmount = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - WaveShape

/// Custom `Shape` rendering a sine-wave water surface sitting at `progress`
/// of the bounding rect (0 = empty / surface at bottom, 1 = full / surface at
/// top). `phase` advances over time to produce horizontal drift.
///
/// Design tokens (art-audit 2026-05-23):
///   - amplitude: 6pt (subtle, never obscures the 64pt ml counter)
///   - wavelength: rect.width / 1.5 (≈ 1.5 cycles across diameter)
///   - sample step: 2pt (smooth on @3x without overdraw)
///   - rendering: filled polygon from wave crest down to bottom edge
struct WaveShape: Shape {
    /// Vertical fill ratio, 0...1. 0 = empty, 1 = full.
    var progress: Double
    /// Phase offset in cycles (1.0 == one full wavelength).
    var phase: Double

    /// Drive the wave drift by animating only `phase` — `progress` is
    /// animated separately via the parent `.animation(_:value:)` modifier.
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let amplitude: CGFloat = 6
        let wavelength = max(rect.width / 1.5, 1)
        // Inset the resting water surface by `amplitude` on each side so the
        // crest never punches above the vessel top or trough below the bottom.
        let surface = rect.height * CGFloat(1 - progress)
        let clampedSurface = min(max(surface, amplitude), rect.height - amplitude)

        path.move(to: CGPoint(x: 0, y: clampedSurface))
        var x: CGFloat = 0
        while x <= rect.width {
            let radians = (x / wavelength + CGFloat(phase)) * 2 * .pi
            let y = clampedSurface + sin(radians) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += 2
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
