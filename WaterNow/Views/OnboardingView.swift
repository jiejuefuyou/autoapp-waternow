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

            // v1.0.5 — Sprint A' residue: rewrite to match v1.0.4 paywall honesty.
            // Earlier copy advertised Dynamic Island / Live Activity / Lock-screen
            // widget / Apple Watch / weekly insights / custom reminders / full
            // history — none of which ship. Only the custom-amount gate exists
            // in the binary (ContentView.customAddButton, IAPManager.isPremium).
            screen(
                index: 1,
                icon: "slider.horizontal.3",
                title: LocalizedStringKey("Log your own amount."),
                subtitle: LocalizedStringKey("Tap once to log. Set custom amounts in ml — no subscription, no ads."),
                color: .blue
            )
            .tag(1)

            screen(
                index: 2,
                icon: "heart.fill",
                title: LocalizedStringKey("$1.99 once."),
                subtitle: LocalizedStringKey("Lifetime unlock. Support an indie developer."),
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
