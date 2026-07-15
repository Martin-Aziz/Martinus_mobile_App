import SwiftUI
import SwiftData

// MARK: - ReentryView
/// PM artifact (P5 bet): welcome-back flow triggered after 7+ days of non-use.
/// Goal: bring a returning user to productive state in < 3 minutes.
/// Kill metric: < 40% of re-entry sessions end with a task action → rebuild this flow.
struct ReentryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var absenceDays: Int
    var overdueCount: Int
    var atRiskGoals: [Goal]
    var onComplete: () -> Void

    @State private var focusInput = ""
    @State private var step: ReentryStep = .welcome

    enum ReentryStep { case welcome, focus, done }

    var body: some View {
        ZStack {
            Color.ffBackground.ignoresSafeArea()
            backgroundGlow

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 40, height: 4)
                    .padding(.top, Spacing.base)
                    .padding(.bottom, Spacing.xl)

                switch step {
                case .welcome: welcomeStep
                case .focus:   focusStep
                case .done:    doneStep
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.xl)
        }
        .onAppear {
            AnalyticsService.shared.record(EventName.reentryFlowShown,
                                           meta: ["absence_days": "\(absenceDays)"])
        }
        .interactiveDismissDisabled()  // prevent accidental swipe-to-dismiss
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: Spacing.xl) {
            // Warm icon — not alarming
            ZStack {
                Circle()
                    .fill(LinearGradient.ffBrand.opacity(0.15))
                    .frame(width: 96, height: 96)
                    .blur(radius: 16)
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(LinearGradient.ffBrand)
            }

            VStack(spacing: Spacing.sm) {
                Text("Welcome back.")
                    .font(.ffDisplay2)
                    .foregroundColor(.ffTextPrimary)
                    .multilineTextAlignment(.center)

                Text("You've been away for \(absenceDays) day\(absenceDays == 1 ? "" : "s").\nLet's take 2 minutes to reconnect.")
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Context summary — shows what's waiting
            if overdueCount > 0 || !atRiskGoals.isEmpty {
                VStack(spacing: Spacing.sm) {
                    if overdueCount > 0 {
                        contextChip(
                            icon:  "clock.badge.exclamationmark.fill",
                            text:  "\(overdueCount) overdue item\(overdueCount == 1 ? "" : "s")",
                            color: .ffWarning
                        )
                    }
                    ForEach(atRiskGoals.prefix(2)) { goal in
                        contextChip(
                            icon:  "exclamationmark.triangle.fill",
                            text:  "\(goal.title) is at risk",
                            color: .ffDanger
                        )
                    }
                }
                .padding(Spacing.base)
                .glassCard()
            }

            FFButton("Let's reconnect", icon: "arrow.right") {
                withAnimation(.easeInOut(duration: 0.3)) { step = .focus }
                HapticManager.medium()
            }

            // Gentle opt-out — not shame-inducing
            Button("Remind me later") {
                AnalyticsService.shared.record(EventName.reentryFlowDismissed)
                dismiss()
            }
            .font(.ffBody)
            .foregroundColor(.ffTextTertiary)
        }
    }

    private var focusStep: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "scope")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(LinearGradient.ffBrand)

            VStack(spacing: Spacing.sm) {
                Text("What matters most\nto you this week?")
                    .font(.ffDisplay2)
                    .foregroundColor(.ffTextPrimary)
                    .multilineTextAlignment(.center)

                Text("One thing. Not a list.")
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
            }

            FFTextField("The one thing that would move the needle...", text: $focusInput)

            FFButton("Set My Focus", icon: "checkmark.circle.fill") {
                setFocusAndComplete()
            }
            .disabled(focusInput.isBlank)
            .opacity(focusInput.isBlank ? 0.5 : 1)

            FFButton("Skip — just show me the app", style: .ghost) {
                AnalyticsService.shared.record(EventName.reentryFlowCompleted,
                                               meta: ["action": "skipped_focus"])
                withAnimation { step = .done }
            }
        }
    }

    private var doneStep: some View {
        VStack(spacing: Spacing.xl) {
            ZStack {
                Circle()
                    .fill(Color.ffSuccess.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(.ffSuccess)
            }

            VStack(spacing: Spacing.sm) {
                Text("You're back.")
                    .font(.ffDisplay2)
                    .foregroundColor(.ffTextPrimary)
                Text("Focus set. Let's build something that matters.")
                    .font(.ffBody)
                    .foregroundColor(.ffTextSecondary)
                    .multilineTextAlignment(.center)
            }

            FFButton("Open Martinus", icon: "arrow.right") {
                onComplete()
                dismiss()
            }
        }
    }

    // MARK: - Helpers

    private func contextChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            Text(text)
                .font(.ffBody)
                .foregroundColor(.ffTextPrimary)
            Spacer()
        }
    }

    private func setFocusAndComplete() {
        guard !focusInput.isBlank else { return }
        // Create a task tagged as the focus for this week
        let task = FocusTask(
            title:      focusInput.trimmed,
            type:       .task,
            priority:   .high,
            scheduledDate: Date()
        )
        task.isMainFocus = true
        appState.taskRepo.insert(task)
        try? appState.taskRepo.save()

        AnalyticsService.shared.record(EventName.reentryFlowCompleted,
                                       meta: ["action": "focus_set"])
        HapticManager.success()
        withAnimation { step = .done }
    }

    private var backgroundGlow: some View {
        ZStack {
            Circle()
                .fill(Color.ffPrimary.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(y: -200)
        }
        .ignoresSafeArea()
    }
}
