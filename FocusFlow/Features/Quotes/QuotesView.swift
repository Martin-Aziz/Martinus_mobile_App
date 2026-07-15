import SwiftUI
import SwiftData

// MARK: - QuotesViewModel
@MainActor
@Observable
final class QuotesViewModel {
    var allQuotes:       [Quote]  = []
    var filteredQuotes:  [Quote]  = []
    var selectedCategory: QuoteCategory? = nil
    var showFavoritesOnly = false
    var searchText        = ""
    var dailyQuote:       Quote?  = nil
    var isLoaded          = false

    private var quoteRepo: QuoteRepository?

    func load(quoteRepo: QuoteRepository) async {
        self.quoteRepo = quoteRepo
        await refresh()
    }

    func refresh() async {
        allQuotes   = (try? quoteRepo?.fetchAll()) ?? []
        dailyQuote  = try? quoteRepo?.fetchDailyQuote(for: Date())
        applyFilter()
        isLoaded    = true
    }

    func applyFilter() {
        var result = allQuotes

        if showFavoritesOnly {
            result = result.filter { $0.isFavorited }
        }
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.text.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        filteredQuotes = result
    }

    func toggleFavorite(_ quote: Quote) {
        quoteRepo?.toggleFavorite(quote)
        HapticManager.light()
        Task { await refresh() }
    }
}

// MARK: - QuotesView
struct QuotesView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = QuotesViewModel()
    @State private var selectedQuote: Quote? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ffBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerBar
                    if let daily = viewModel.dailyQuote {
                        dailyHero(daily)
                            .padding(.horizontal, Spacing.base)
                            .padding(.bottom, Spacing.sm)
                    }
                    filterBar
                    FFDivider()
                    quoteList
                }
            }
            .task { await viewModel.load(quoteRepo: appState.quoteRepo) }
            .sheet(item: $selectedQuote) { quote in
                QuoteDetailSheet(quote: quote, onFavorite: { viewModel.toggleFavorite(quote) })
            }
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Text("Quotes")
                .font(.ffDisplay2)
                .foregroundColor(.ffTextPrimary)
            Spacer()
            Button(action: {
                viewModel.showFavoritesOnly.toggle()
                viewModel.applyFilter()
            }) {
                Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.showFavoritesOnly ? .ffDanger : .ffTextSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color.ffSurfaceElevated)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, Spacing.base)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Daily Hero Card
    private func dailyHero(_ quote: Quote) -> some View {
        Button(action: { selectedQuote = quote }) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Daily Motivation")
                        .font(.ffCaption)
                        .foregroundColor(.ffTextSecondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    Spacer()
                    TagChip(quote.category.label, color: .ffPrimary)
                }
                Text("“\(quote.text)”")
                    .font(.ffQuote)
                    .foregroundColor(.ffTextPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text("— \(quote.displayAuthor)")
                        .font(.ffBodyMed)
                        .foregroundStyle(LinearGradient.ffBrand)
                    Spacer()
                    Image(systemName: quote.isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(quote.isFavorited ? .ffDanger : .ffTextSecondary)
                        .onTapGesture { viewModel.toggleFavorite(quote) }
                }
            }
            .padding(Spacing.base)
            .glassCard(cornerRadius: Radius.lg)
        }
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                TagChip("All", color: .ffPrimary, isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                    viewModel.applyFilter()
                }
                ForEach(QuoteCategory.allCases) { cat in
                    TagChip(cat.label, color: .ffPrimary, isSelected: viewModel.selectedCategory == cat) {
                        viewModel.selectedCategory = (viewModel.selectedCategory == cat) ? nil : cat
                        viewModel.applyFilter()
                    }
                }
            }
            .padding(.horizontal, Spacing.base)
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Quotes List
    private var quoteList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.filteredQuotes) { quote in
                    QuoteRow(quote: quote, onTap: { selectedQuote = quote }, onFavorite: { viewModel.toggleFavorite(quote) })
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - QuoteRow
struct QuoteRow: View {
    var quote:      Quote
    var onTap:      () -> Void
    var onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("“\(quote.text)”")
                        .font(.ffBody)
                        .foregroundColor(.ffTextPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    Text("— \(quote.displayAuthor)")
                        .font(.ffCaption)
                        .foregroundColor(.ffTextSecondary)
                    TagChip(quote.category.label, color: .ffPrimary)
                }
                Spacer()
                Button(action: onFavorite) {
                    Image(systemName: quote.isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(quote.isFavorited ? .ffDanger : .ffTextSecondary)
                }
            }
            .padding(Spacing.base)
            .glassCard()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - QuoteDetailSheet
struct QuoteDetailSheet: View {
    var quote:      Quote
    var onFavorite: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isFavorited: Bool = false

    var body: some View {
        ZStack {
            Color.ffBackground.ignoresSafeArea()
            VStack(spacing: Spacing.xl) {
                // Pull indicator
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, Spacing.base)

                Spacer()

                VStack(spacing: Spacing.xl) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(LinearGradient.ffBrand)

                    Text(quote.text)
                        .font(.ffQuote)
                        .foregroundColor(.ffTextPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 4) {
                        Text("— \(quote.displayAuthor)")
                            .font(.ffBodyMed)
                            .foregroundStyle(LinearGradient.ffBrand)
                        if let source = quote.source {
                            Text(source)
                                .font(.ffCaption)
                                .foregroundColor(.ffTextSecondary)
                        }
                    }

                    if !quote.explanation.isEmpty {
                        Text(quote.explanation)
                            .font(.ffBody)
                            .foregroundColor(.ffTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                }

                Spacer()

                HStack(spacing: Spacing.xl) {
                    CircularIconButton(
                        isFavorited ? "heart.fill" : "heart",
                        color: isFavorited ? .ffDanger : .ffTextSecondary,
                        size: 52
                    ) {
                        isFavorited.toggle()
                        onFavorite()
                    }

                    ShareLink(item: "“\(quote.text)” — \(quote.displayAuthor)") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 22))
                            .foregroundColor(.ffTextSecondary)
                            .frame(width: 52, height: 52)
                            .background(Color.ffSurfaceElevated)
                            .clipShape(Circle())
                    }

                    TagChip(quote.category.label, color: .ffPrimary)
                }
                .padding(.bottom, Spacing.xxl)
            }
            .padding(Spacing.base)
        }
        .onAppear { isFavorited = quote.isFavorited }
    }
}
