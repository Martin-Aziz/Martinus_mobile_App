import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        ZStack {
            // System background — deep dark from design
            CinematicBackgroundView()

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
            .tabViewStyle(.page(indexDisplayMode: .never))
            .tint(.ffPrimary)
            .overlay(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.58)
                        .frame(height: 82)
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black.opacity(0.45), location: 0.32),
                                    .init(color: .black, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)

                    TransparentLiquidTabBar(selection: Binding(
                        get: { appState.selectedTab },
                        set: { appState.selectedTab = $0 }
                    ))
                    .padding(.bottom, 4)
                }
            }
            .onAppear {
                // iOS 26 tab bars adopt native Liquid Glass automatically. Custom
                // UITabBar backgrounds suppress that rendering, so only style the
                // compatibility path on older systems.
                if #unavailable(iOS 26.0) {
                    configureLegacyTabBarAppearance()
                }
            }
        }
        .preferredColorScheme(appState.appearance.colorScheme)
        .id("\(appState.fontStyle.rawValue)-\(appState.appearance.rawValue)")
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
        .sheet(item: Binding(
            get: { appState.motivationMoment },
            set: { appState.motivationMoment = $0 }
        )) { moment in
            MotivationMomentView(moment: moment)
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

    private func configureLegacyTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: appState.appearance == .light ? .systemUltraThinMaterialLight : .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(Color.ffBackground.opacity(0.42))

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

private struct TransparentLiquidTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 8) {
                tabButtons
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        } else {
            tabButtons
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
    }

    private var tabButtons: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selection == tab ? .semibold : .medium))
                        Text(tab.title)
                            .font(.system(size: 10, weight: selection == tab ? .semibold : .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selection == tab ? Color.ffPrimary : Color.ffTextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .modifier(LiquidTabItemEffect(isSelected: selection == tab))
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
    }
}

private struct LiquidTabItemEffect: ViewModifier {
    let isSelected: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if isSelected {
                content.glassEffect(
                    .clear.tint(Color.ffPrimary.opacity(0.14)).interactive(),
                    in: .capsule
                )
            } else {
                content
            }
        } else if isSelected {
            content.background(.ultraThinMaterial, in: Capsule())
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}

struct MotivationMomentView: View {
    let moment: MotivationMoment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CinematicBackgroundView()
            VStack(spacing: Spacing.xl) {
                Spacer()
                Image(systemName: moment.symbol)
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(LinearGradient.ffBrand)
                Text(moment.title)
                    .font(.ffDisplay2)
                    .foregroundColor(.ffTextPrimary)
                    .multilineTextAlignment(.center)
                Text(moment.message)
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
                    .multilineTextAlignment(.center)
                VStack(spacing: Spacing.sm) {
                    Text("“\(moment.quote)”")
                        .font(.ffQuote)
                        .foregroundColor(.ffTextPrimary)
                        .multilineTextAlignment(.center)
                    Text("— \(moment.author)")
                        .font(.ffBodyMed)
                        .foregroundStyle(LinearGradient.ffBrand)
                }
                .padding(Spacing.xl)
                .glassCard(cornerRadius: Radius.lg)
                Spacer()
                FFButton("Keep Going", icon: "arrow.right") { dismiss() }
            }
            .padding(Spacing.xl)
        }
        .presentationDetents([.medium, .large])
    }
}
