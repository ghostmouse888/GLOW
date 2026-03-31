import SwiftUI
import Combine

final class AppState: ObservableObject {

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userName")  var userName:  String = ""
    @AppStorage("userAge")   var userAge:   Int    = 0
    @AppStorage("streakDays") var streakDays: Int  = 0
    @AppStorage("lastCheckIn") private var lastCheckInString: String = ""

    var lastCheckInDate: Date? {
        get { ISO8601DateFormatter().date(from: lastCheckInString) }
        set { lastCheckInString = newValue.map { ISO8601DateFormatter().string(from: $0) } ?? "" }
    }

    @Published var moodHistory: [MoodEntry] = [] {
        didSet { saveMoodHistory() }
    }

    @Published var localResources: [LocalResource] = []

    init() { loadMoodHistory() }

    func recordCheckIn(mood: Mood, energy: Int) {
        let entry = MoodEntry(mood: mood, energy: energy, date: .now)
        moodHistory.append(entry)
        if moodHistory.count > 7 { moodHistory.removeFirst() }
        let cal = Calendar.current
        if let last = lastCheckInDate, cal.isDateInYesterday(last) {
            streakDays += 1
        } else if lastCheckInDate == nil || !cal.isDateInToday(lastCheckInDate!) {
            streakDays = 1
        }
        lastCheckInDate = .now
    }

    private func saveMoodHistory() {
        if let data = try? JSONEncoder().encode(moodHistory) {
            UserDefaults.standard.set(data, forKey: "moodHistory")
        }
    }

    private func loadMoodHistory() {
        guard let data = UserDefaults.standard.data(forKey: "moodHistory"),
              let entries = try? JSONDecoder().decode([MoodEntry].self, from: data)
        else { return }
        moodHistory = entries
    }
}
