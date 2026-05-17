import SwiftUI

struct ContentView: View {
    @Environment(IAPManager.self) private var iap
    @Environment(HydrationStore.self) private var store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var selectedBeverage: BeverageType = .water

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                progressRing

                Text("\(store.todayTotal()) / \(store.dailyGoalML) ml")
                    .font(.title.bold().monospacedDigit())

                Text("\(Int(store.todayPercent() * 100))% of daily goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                beveragePicker
                    .padding(.horizontal)

                cupSizeButtons
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("WaterNow")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gear") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !iap.isPremium {
                        Button { showPaywall = true } label: {
                            Label("Pro", systemImage: "sparkles").font(.caption.bold())
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
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
        Picker("Beverage", selection: $selectedBeverage) {
            ForEach(BeverageType.allCases) { b in
                Text("\(b.emoji) \(b.displayName)").tag(b)
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
                        Text(size.displayName)
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
