import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        ZStack {
            // System background — deep dark from design
            Color.ffBackground.ignoresSafeArea()

            TabView(selection: Binding(
                get: { appState.selectedTab },
                set: { appState.selectedTab = $0 }
            )) {
                HomeView()
                    .tabItem { Label("Home",    systemImage: "house.fill") }
                    .tag(AppTab.home)

                TodayView()
                    .tabItem { Label("Today",   systemImage: "calendar") }
                    .tag(AppTab.today)

                GoalsView()
                    .tabItem { Label("Goals",   systemImage: "target") }
                    .tag(AppTab.goals)

                JournalView()
                    .tabItem { Label("Journal", systemImage: "book.fill") }
                    .tag(AppTab.journal)

                QuotesView()
                    .tabItem { Label("Quotes",  systemImage: "quote.bubble.fill") }
                    .tag(AppTab.quotes)

                MoreView()
                    .tabItem { Label("More",    systemImage: "ellipsis") }
                    .tag(AppTab.more)
            }
            .tint(.ffPrimary)
            .onAppear {
                configureTabBarAppearance()
            }
        }
        .preferredColorScheme(.dark)
        .id(appState.fontStyle.rawValue)
        .fullScreenCover(isPresented: Binding(
            get: { appState.showOnboarding },
            set: { appState.showOnboarding = $0 }
        )) {
            OnboardingView()
        }
        .sheet(isPresented: Binding(
            get: { appState.showAddTask },
            set: { appState.showAddTask = $0 }
        )) {
            AddTaskView()
        }
        .sheet(isPresented: Binding(
            get: { appState.showAddGoal },
            set: { appState.showAddGoal = $0 }
        )) {
            AddGoalView()
        }
        .sheet(isPresented: Binding(
            get: { appState.showFocusSession },
            set: { appState.showFocusSession = $0 }
        )) {
            FocusSessionView()
        }
        // PM artifact P5: re-entry flow after 7+ days absence
        .sheet(isPresented: Binding(
            get: { appState.showReentry },
            set: { appState.showReentry = $0 }
        )) {
            ReentryView(
                absenceDays:  appState.reentryAbsenceDays,
                overdueCount: appState.reentryOverdueCount,
                atRiskGoals:  appState.reentryAtRiskGoals,
                onComplete:   {
                    appState.userProfile?.consecutiveAbsenceDays = 0
                    try? appState.profileRepo.save()
                }
            )
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor  = UIColor(Color.ffBackground.opacity(0.85))

        let border = UIView()
        border.backgroundColor = UIColor(white: 1, alpha: 0.08)

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Normal state
        let normalAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.ffTextSecondary)
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttr
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.ffTextSecondary)

        // Selected state
        let selectedAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.ffPrimary)
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttr
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.ffPrimary)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
