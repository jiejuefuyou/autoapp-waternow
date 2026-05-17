import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentScreen = 0

    var body: some View {
        TabView(selection: $currentScreen) {
            screen(
                index: 0,
                icon: "drop.fill",
                title: "Stay hydrated.",
                subtitle: "Tap a cup size — water, tea, coffee — and watch your daily goal fill up.",
                color: .cyan
            )
            .tag(0)

            screen(
                index: 1,
                icon: "waveform.path.ecg",
                title: "Live in your Dynamic Island.",
                subtitle: "Pro: Live Activity shows progress all day. Lock screen widget for one-tap log.",
                color: .blue
            )
            .tag(1)

            screen(
                index: 2,
                icon: "applewatch",
                title: "$1.99 once.",
                subtitle: "Pro: full history, Apple Watch, custom reminders, weekly insights. No subscription.",
                color: .accentColor,
                showCTA: true
            )
            .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
    }

    private func screen(
        index: Int,
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        showCTA: Bool = false
    ) -> some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(color)
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            if showCTA {
                Button {
                    hasSeenOnboarding = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(color, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            } else {
                Spacer().frame(height: 80)
            }
        }
    }
}
