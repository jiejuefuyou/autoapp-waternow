import SwiftUI

struct SettingsView: View {
    @Environment(IAPManager.self) private var iap
    @Environment(HydrationStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var goalDraft: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Goal") {
                    HStack {
                        Text("Goal (ml)")
                        Spacer()
                        TextField("2000", text: $goalDraft)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .onSubmit(applyGoal)
                    }
                    Button("Apply", action: applyGoal)
                }

                Section("Premium") {
                    if iap.isPremium {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                    } else {
                        Button { showPaywall = true } label: {
                            Label("Unlock Pro", systemImage: "sparkles")
                        }
                    }
                    Button("Restore Purchase") { Task { await iap.restore() } }
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build",   value: buildNumber)
                    Link("Privacy Policy", destination: URL(string: "https://github.com/jiejuefuyou/autoapp-waternow/blob/main/PRIVACY.md")!)
                    Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    Label("No data collected. Ever.", systemImage: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .onAppear {
                goalDraft = "\(store.dailyGoalML)"
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func applyGoal() {
        if let v = Int(goalDraft.trimmingCharacters(in: .whitespaces)), v > 0 {
            store.setGoal(v)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}
