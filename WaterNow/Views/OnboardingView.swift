import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentScreen = 0

    var body: some View {
        TabView(selection: $currentScreen) {
            screen(
                index: 0,
                icon: "drop.fill",
                title: LocalizedStringKey("Stay hydrated."),
                subtitle: LocalizedStringKey("Tap a cup size — water, tea, coffee — and watch your daily goal fill up."),
                color: .cyan
            )
            .tag(0)

            screen(
                index: 1,
                icon: "waveform.path.ecg",
                title: LocalizedStringKey("Live in your Dynamic Island."),
                subtitle: LocalizedStringKey("Pro: Live Activity shows progress all day. Lock screen widget for one-tap log."),
                color: .blue
            )
            .tag(1)

            screen(
                index: 2,
                icon: "applewatch",
                title: LocalizedStringKey("$1.99 once."),
                subtitle: LocalizedStringKey("Pro: full history, Apple Watch, custom reminders, weekly insights. No subscription."),
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
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        color: Color,
        showCTA: Bool = false
    ) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            // Hero glyph — fixed 80pt weight intentional (not Dynamic Type).
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
                .padding(.horizontal, Spacing.xl)
            Spacer()
            if showCTA {
                Button {
                    hasSeenOnboarding = true
                } label: {
                    Text(LocalizedStringKey("Get Started"))
                        .font(Typography.bodyEmphasis)
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md)
                        .background(color, in: RoundedRectangle(cornerRadius: Radius.md))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
                .padding(.bottom, Spacing.xl)
            } else {
                Spacer().frame(height: 80)
            }
        }
    }
}
