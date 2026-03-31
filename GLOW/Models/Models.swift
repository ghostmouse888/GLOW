import Foundation
import SwiftUI

// MARK: — Color helper (available across all files in module)
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: — Chat
struct Message: Identifiable, Codable {
    let id:      UUID
    let role:    Role
    let content: String
    let date:    Date

    init(role: Role, content: String) {
        self.id = UUID(); self.role = role
        self.content = content; self.date = .now
    }

    enum Role: String, Codable { case user, assistant }
}

// MARK: — Mood
enum Mood: String, Codable, CaseIterable {
    case great, okay, low, anxious, angry

    var label:  String { rawValue.capitalized }
    var emoji:  String {
        switch self {
        case .great: return "😊"; case .okay: return "😐"
        case .low:   return "😔"; case .anxious: return "😰"
        case .angry: return "😤"
        }
    }
}

struct MoodEntry: Identifiable, Codable {
    let id: UUID; let mood: Mood; let energy: Int; let date: Date
    init(mood: Mood, energy: Int, date: Date = .now) {
        self.id = UUID(); self.mood = mood
        self.energy = energy; self.date = date
    }
    var dayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return f.string(from: date)
    }
}

// MARK: — Resources
struct LocalResource: Identifiable, Codable {
    let id: UUID; let name: String; let phone: String; let address: String
    init(name: String, phone: String, address: String) {
        self.id = UUID(); self.name = name
        self.phone = phone; self.address = address
    }
}

// MARK: — Wins
struct WinEntry: Identifiable, Codable {
    let id:       UUID
    let bigWin:   String
    let smallWin: String
    let grateful: String
    let response: String
    let date:     Date
    init(bigWin: String, smallWin: String, grateful: String, response: String) {
        self.id = UUID(); self.bigWin = bigWin
        self.smallWin = smallWin; self.grateful = grateful
        self.response = response; self.date = .now
    }
}

// MARK: — Body Check
struct BodyCheckEntry: Identifiable, Codable {
    let id:        UUID
    let energy:    Int
    let hunger:    Int
    let tiredness: Int
    let tension:   [String]
    let response:  String
    let date:      Date
    init(energy: Int, hunger: Int, tiredness: Int, tension: [String], response: String) {
        self.id = UUID(); self.energy = energy
        self.hunger = hunger; self.tiredness = tiredness
        self.tension = tension; self.response = response; self.date = .now
    }
}

// MARK: — Thought
struct ThoughtEntry: Identifiable, Codable {
    let id:       UUID
    let original: String
    let refresh:  String
    let date:     Date
    init(original: String, refresh: String) {
        self.id = UUID(); self.original = original
        self.refresh = refresh; self.date = .now
    }
}
