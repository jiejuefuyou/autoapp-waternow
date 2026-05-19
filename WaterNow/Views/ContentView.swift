import SwiftUI

struct ContentView: View {
    @Environment(IAPManager.self) private var iap
    @Environment(HydrationStore.self) private var store
    @Environment(LocalizationManager.self) private var l10n

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var selectedBeverage: BeverageType = .water

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                progressRing

                Text("\(store.todayTotal()) / \(store.dailyGoalML) ml")
                    .font(.title.bold().monospacedDigit())

                Text(String(format: NSLocalizedString("%@ of daily goal", comment: "Percent label under hydration ring"),
                            "\(Int(store.todayPercent() * 100))%"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                beveragePicker
                    .padding(.horizontal)

                cupSizeButtons
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle(Text("WaterNow"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gear") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !iap.isPremium {
                        Button { showPaywall = true } label: {
                            Label(LocalizedStringKey("Pro"), systemImage: "sparkles").font(.caption.bold())
                        }
                    }
                }
            }
            // CRITICAL: SwiftUI sheet/fullScreenCover attaches modal to scene
            // presentation host, NOT to ContentView's view tree. The .id on
            // WaterNowApp.swift only rebuilds ContentView itself — modal
            // content stays stale on language change. Force rebuild per-modal.
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(l10n)
                    .environment(\.locale, l10n.currentLocale)
                    .id(l10n.override)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environment(l10n)
                    .environment(\.locale, l10n.currentLocale)
                    .id(l10n.override)
            }
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(.tertiary, lineWidth: 16)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: store.todayPercent())
                .stroke(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 200, height: 200)
                .animation(.easeInOut, value: store.todayPercent())

            Text(BeverageType.water.emoji)
                .font(.system(size: 60))
        }
    }

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

    private var cupSizeButtons: some View {
        VStack(spacing: 8) {
            ForEach(CupSize.allCases) { size in
                Button {
                    store.add(size.rawValue, beverage: selectedBeverage)
                } label: {
                    HStack {
                        Text(LocalizedStringKey(size.displayName))
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
