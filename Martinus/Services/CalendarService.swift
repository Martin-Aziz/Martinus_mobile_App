import Foundation
import EventKit
import UIKit

// MARK: - CalendarService
/// Reads calendar events from the system EventKit calendar for the Today timeline.
@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()
    private let eventStore = EKEventStore()

    @Published var isAuthorized = false
    @Published var todayEvents: [CalendarEvent] = []

    private init() {}

    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            isAuthorized = granted
            if granted { await loadTodayEvents() }
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = (status == .fullAccess || status == .authorized)
    }

    func loadTodayEvents() async {
        guard isAuthorized else { return }

        let start = Date().startOfDay
        let end   = Date().endOfDay
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents  = eventStore.events(matching: predicate)

        todayEvents = ekEvents.map { event in
            CalendarEvent(
                id:        event.eventIdentifier ?? UUID().uuidString,
                title:     event.title ?? "Event",
                startDate: event.startDate,
                endDate:   event.endDate,
                isAllDay:  event.isAllDay,
                calendarColor: event.calendar.cgColor.map { UIColor(cgColor: $0).hexString } ?? "#8C65FF"
            )
        }.sorted { $0.startDate < $1.startDate }
    }

    func loadEvents(for date: Date) async -> [CalendarEvent] {
        guard isAuthorized else { return [] }

        let start = date.startOfDay
        let end   = date.endOfDay
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents  = eventStore.events(matching: predicate)

        return ekEvents.map { event in
            CalendarEvent(
                id:        event.eventIdentifier ?? UUID().uuidString,
                title:     event.title ?? "Event",
                startDate: event.startDate,
                endDate:   event.endDate,
                isAllDay:  event.isAllDay,
                calendarColor: event.calendar.cgColor.map { UIColor(cgColor: $0).hexString } ?? "#8C65FF"
            )
        }.sorted { $0.startDate < $1.startDate }
    }
}

// MARK: - CalendarEvent (transient view model)
struct CalendarEvent: Identifiable {
    var id:            String
    var title:         String
    var startDate:     Date
    var endDate:       Date
    var isAllDay:      Bool
    var calendarColor: String

    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }
}

// MARK: - UIColor hex extension
private extension UIColor {
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
