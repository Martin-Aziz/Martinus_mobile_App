import SwiftUI
import SwiftData

// MARK: - OnboardingView
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var page    = 0
    @State private var name    = ""
    @State private var requestedNotifications = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon:      "sparkles",
            title:     "Welcome to Martinus",
            subtitle:  "Your personal assistant for goals, reflection, and motivation.",
            detail:    "Plan your day. Achieve your goals.\nReflect with intention. Stay motivated.",
            gradient:  .ffBrand
        ),
        OnboardingPage(
            icon:      "target",
            title:     "Set Meaningful Goals",
            subtitle:  "Break big goals into milestones and track real progress.",
            detail:    "Martinus keeps your goals visible every day — not hidden in a list you never open.",
            gradient:  .ffCyan
        ),
        OnboardingPage(
            icon:      "scope",
            title:     "One Focus at a Time",
            subtitle:  "Choose one main priority each day and protect your attention.",
            detail:    "Your brain can only truly focus on one thing. Martinus helps you honor that reality.",
            gradient:  .ffPurpleDeep
        ),
        OnboardingPage(
            icon:      "book.fill",
            title:     "Reflect and Grow",
            subtitle:  "A two-minute journal builds clarity and self-awareness over time.",
            detail:    "Understanding your patterns is how you change them.",
            gradient:  .ffSuccess
        ),
        OnboardingPage(
            icon:      "bell.badge.fill",
            title:     "Smart Reminders",
            subtitle:  "Martinus nudges you at the right moment, not constantly.",
            detail:    "Personal notifications that feel like a supportive assistant, not noise.",
            gradient:  .ffWarning
        )
    ]

    var body: some View {
        ZStack {
            CinematicBackgroundView(variant: 1)
            backgroundBlobs

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: Spacing.xs) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.ffPrimary : Color.white.opacity(0.2))
                            .frame(width: i == page ? 24 : 8, height: 8)
                            .animation(.spring(duration: 0.3), value: page)
                    }
                }
                .padding(.top, Spacing.xxl)

                Spacer()

                // Page content
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        pageView(pages[i])
                            .tag(i)
                    }
                    nameEntryPage.tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                Spacer()

                // Navigation buttons
                VStack(spacing: Spacing.sm) {
                    if page < pages.count - 1 {
                        FFButton("Continue", icon: "arrow.right") {
                            withAnimation { page += 1 }
                            HapticManager.light()
                        }
                    } else if page == pages.count - 1 {
                        FFButton("Get Started", icon: "sparkles") {
                            withAnimation { page = pages.count }
                            HapticManager.medium()
                        }
                    } else {
                        FFButton("Let's Begin", icon: "checkmark.circle.fill") {
                            finishOnboarding()
                        }
                        .disabled(name.isBlank)
                        .opacity(name.isBlank ? 0.5 : 1)
                    }

                    if page < pages.count {
                        Button("Skip") {
                            withAnimation { page = pages.count }
                        }
                        .font(.ffBody)
                        .foregroundColor(.ffTextTertiary)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }
        }
    }

    // MARK: - Page View
    private func pageView(_ p: OnboardingPage) -> some View {
        VStack(spacing: Spacing.xl) {
            ZStack {
                Circle()
                    .fill(p.gradient.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                Image(systemName: p.icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(p.gradient)
            }

            VStack(spacing: Spacing.md) {
                Text(p.title)
                    .font(.ffDisplay2)
                    .foregroundColor(.ffTextPrimary)
                    .multilineTextAlignment(.center)
                Text(p.subtitle)
                    .font(.ffHeadline3)
                    .foregroundColor(.ffTextSecondary)
                    .multilineTextAlignment(.center)
                Text(p.detail)
                    .font(.ffBody)
                    .foregroundColor(.ffTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .padding(.horizontal, Spacing.base)
    }

    // MARK: - Name Entry Page
    private var nameEntryPage: some View {
        VStack(spacing: Spacing.xl) {
            ZStack {
                Circle()
                    .fill(LinearGradient.ffBrand.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                Image(systemName: "person.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(LinearGradient.ffBrand)
            }

            VStack(spacing: Spacing.sm) {
                Text("What should I call you?")
                    .font(.ffDisplay2)
                    .foregroundColor(.ffTextPrimary)
                    .multilineTextAlignment(.center)
                Text("This is your personal space. Make it yours.")
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
                    .multilineTextAlignment(.center)
            }

            FFTextField("Your first name...", text: $name, icon: "person")

            if !requestedNotifications {
                GlassCard(cornerRadius: Radius.md) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(LinearGradient.ffBrand)
                        Text("Enable Notifications")
                            .font(.ffHeadline3)
                            .foregroundColor(.ffTextPrimary)
                        Text("Receive gentle reminders that keep you on track — never spam.")
                            .font(.ffBody)
                            .foregroundColor(.ffTextSecondary)
                            .multilineTextAlignment(.center)
                        FFButton("Enable", icon: "bell.fill") {
                            requestNotifications()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, Spacing.base)
    }

    private var backgroundBlobs: some View {
        ZStack {
            Circle()
                .fill(Color.ffPrimary.opacity(0.10))
                .frame(width: 350, height: 350)
                .blur(radius: 100)
                .offset(x: -120, y: -250)
            Circle()
                .fill(Color.ffSecondary.opacity(0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: 130, y: 200)
        }
        .ignoresSafeArea()
    }

    private func requestNotifications() {
        Task {
            let granted = await NotificationService.shared.requestAuthorization()
            requestedNotifications = true
            if granted {
                await NotificationService.shared.scheduleMorningBriefing(hour: 8, minute: 0)
                await NotificationService.shared.scheduleEveningReview(hour: 21, minute: 0)
            }
        }
    }

    private func finishOnboarding() {
        appState.userProfile?.name           = name.trimmed.isEmpty ? "Friend" : name.trimmed
        appState.userProfile?.onboardingDone = true
        try? UserProfileRepository(modelContext: modelContext).save()
        HapticManager.success()
        appState.showOnboarding = false
    }
}

// MARK: - OnboardingPage Model
struct OnboardingPage {
    var icon:     String
    var title:    String
    var subtitle: String
    var detail:   String
    var gradient: LinearGradient
}
