import Foundation
import SwiftUI

// MARK: — Zone

enum FaceZone: String, CaseIterable, Identifiable {
    case eyes   = "Eyes"
    case cheeks = "Cheeks"
    case nose   = "Nose"
    case mouth  = "Mouth"
    case jaw    = "Jaw"
    case neck   = "Neck"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .eyes:   return "👀"
        case .cheeks: return "😊"
        case .nose:   return "👃"
        case .mouth:  return "👄"
        case .jaw:    return "🦷"
        case .neck:   return "🙆"
        }
    }

    var color: Color {
        switch self {
        case .eyes:   return Color(hex: "#1D9E75")
        case .cheeks: return Color(hex: "#EF9F27")
        case .nose:   return Color(hex: "#7F77DD")
        case .mouth:  return Color(hex: "#D85A30")
        case .jaw:    return Color(hex: "#E24B4A")
        case .neck:   return Color(hex: "#378ADD")
        }
    }

    var bgColor: Color {
        switch self {
        case .eyes:   return Color(hex: "#E1F5EE")
        case .cheeks: return Color(hex: "#FAEEDA")
        case .nose:   return Color(hex: "#EEEDFE")
        case .mouth:  return Color(hex: "#FAECE7")
        case .jaw:    return Color(hex: "#FCEBEB")
        case .neck:   return Color(hex: "#E6F1FB")
        }
    }

    var duration: String {
        switch self {
        case .eyes:   return "~4 min"
        case .cheeks: return "~4 min"
        case .nose:   return "~3 min"
        case .mouth:  return "~4 min"
        case .jaw:    return "~3 min"
        case .neck:   return "~3 min"
        }
    }

    var exerciseCount: Int {
        FaceExercise.all.filter { $0.zone == self }.count
    }
}

// MARK: — Detection threshold

struct DetectionThreshold {
    // Each field is optional — only set the ones relevant to the exercise
    var jawOpennessMin:  Float? = nil
    var jawOpennessMax:  Float? = nil
    var eyeOpenMin:      Float? = nil
    var eyeOpenMax:      Float? = nil
    var smileMin:        Float? = nil
    var smileMax:        Float? = nil
    var browRaiseMin:    Float? = nil
    var mouthOpenMin:    Float? = nil
    var mouthOpenMax:    Float? = nil

    func isMet(by reading: FaceReading) -> Bool {
        if let min = jawOpennessMin,  reading.jawOpenness < min  { return false }
        if let max = jawOpennessMax,  reading.jawOpenness > max  { return false }
        if let min = eyeOpenMin,      reading.eyeOpen < min      { return false }
        if let max = eyeOpenMax,      reading.eyeOpen > max      { return false }
        if let min = smileMin,        reading.smileAmount < min  { return false }
        if let max = smileMax,        reading.smileAmount > max  { return false }
        if let min = browRaiseMin,    reading.browRaise < min    { return false }
        if let min = mouthOpenMin,    reading.mouthOpenness < min { return false }
        if let max = mouthOpenMax,    reading.mouthOpenness > max { return false }
        return true
    }
}

// MARK: — Exercise model

struct FaceExercise: Identifiable {
    let id:          String
    let name:        String
    let zone:        FaceZone
    let muscle:      String
    let instruction: String
    let tip:         String
    let emoji:       String
    let holdSeconds: Int
    let threshold:   DetectionThreshold

    // MARK: — All 15 exercises

    static let all: [FaceExercise] = [

        // ── EYES ──────────────────────────────────────────
        FaceExercise(
            id: "wide_eyes",
            name: "Wide eye hold",
            zone: .eyes,
            muscle: "Ocular muscle",
            instruction: "Open your eyes as wide as you possibly can and hold perfectly still.",
            tip: "Try not to raise your eyebrows — use just your eye muscles.",
            emoji: "👀",
            holdSeconds: 5,
            threshold: DetectionThreshold(eyeOpenMin: 0.82)
        ),
        FaceExercise(
            id: "slow_blink",
            name: "Slow blink",
            zone: .eyes,
            muscle: "Ocular muscle",
            instruction: "Close your eyes very slowly, hold them shut gently, then open slowly.",
            tip: "Keep your face completely relaxed — no squinting.",
            emoji: "😌",
            holdSeconds: 3,
            threshold: DetectionThreshold(eyeOpenMax: 0.15)
        ),
        FaceExercise(
            id: "half_squint",
            name: "Half-eye squint",
            zone: .eyes,
            muscle: "Procerus muscle",
            instruction: "Half-close your eyes and raise your top lip at the same time. Hold.",
            tip: "This is the hardest eye exercise — the Procerus muscle rarely gets used.",
            emoji: "😏",
            holdSeconds: 4,
            threshold: DetectionThreshold(eyeOpenMax: 0.5, smileMin: 0.2)
        ),

        // ── CHEEKS ────────────────────────────────────────
        FaceExercise(
            id: "cheek_puff",
            name: "Cheek puff",
            zone: .cheeks,
            muscle: "Buccinator muscle",
            instruction: "Pucker your lips, suck in your cheeks, then puff them out as wide as possible with air.",
            tip: "Keep your lips sealed — no air should escape.",
            emoji: "🐡",
            holdSeconds: 5,
            threshold: DetectionThreshold(jawOpennessMax: 0.25)
        ),
        FaceExercise(
            id: "big_smile",
            name: "Big smile hold",
            zone: .cheeks,
            muscle: "Zygomaticus major",
            instruction: "Give the biggest, widest smile you possibly can and hold it.",
            tip: "Show your teeth! The wider the better for the Zygomaticus major.",
            emoji: "😁",
            holdSeconds: 5,
            threshold: DetectionThreshold(smileMin: 0.65)
        ),
        FaceExercise(
            id: "cheek_suck",
            name: "Cheek hollow",
            zone: .cheeks,
            muscle: "Buccinator muscle",
            instruction: "Suck both cheeks inward as hard as you can, forming a fish face, and hold.",
            tip: "Imagine you're trying to touch your cheeks together inside your mouth.",
            emoji: "😗",
            holdSeconds: 4,
            threshold: DetectionThreshold(jawOpennessMax: 0.2, smileMax: 0.15)
        ),

        // ── NOSE ──────────────────────────────────────────
        FaceExercise(
            id: "nose_wrinkle",
            name: "Nose scrunch",
            zone: .nose,
            muscle: "Procerus muscle",
            instruction: "Scrunch your nose upward as hard as you can, like you smell something bad. Hold.",
            tip: "Really push — most people barely use this muscle in daily life.",
            emoji: "🤨",
            holdSeconds: 3,
            threshold: DetectionThreshold(browRaiseMin: 0.45)
        ),
        FaceExercise(
            id: "upper_lip_raise",
            name: "Upper lip raise",
            zone: .nose,
            muscle: "Levator labii",
            instruction: "Raise your upper lip as high as possible without opening your mouth or smiling. Hold.",
            tip: "Keep your teeth together — only the upper lip should move.",
            emoji: "😬",
            holdSeconds: 4,
            threshold: DetectionThreshold(jawOpennessMax: 0.2, smileMin: 0.25)
        ),

        // ── MOUTH ─────────────────────────────────────────
        FaceExercise(
            id: "o_mouth",
            name: "O mouth hold",
            zone: .mouth,
            muscle: "Orbicularis oris",
            instruction: "Form a wide, round O shape with your lips and hold it open.",
            tip: "Make the O as large and round as you can — stretch those lip muscles.",
            emoji: "😮",
            holdSeconds: 5,
            threshold: DetectionThreshold(jawOpennessMin: 0.45, smileMax: 0.2)
        ),
        FaceExercise(
            id: "tongue_out",
            name: "Tongue stretch",
            zone: .mouth,
            muscle: "Lingual muscle",
            instruction: "Open your mouth wide and stick your tongue out as far as it will go. Hold.",
            tip: "Then try moving it slowly left, hold, then right. Great for chin definition.",
            emoji: "😛",
            holdSeconds: 4,
            threshold: DetectionThreshold(jawOpennessMin: 0.55)
        ),
        FaceExercise(
            id: "lip_stretch",
            name: "Wide lip stretch",
            zone: .mouth,
            muscle: "Orbicularis oris",
            instruction: "Pull your lips back in a wide, flat stretch — like an exaggerated grin. Hold.",
            tip: "Different from smiling — keep it flat and horizontal, teeth together.",
            emoji: "😬",
            holdSeconds: 4,
            threshold: DetectionThreshold(jawOpennessMax: 0.2, smileMin: 0.75)
        ),

        // ── JAW ───────────────────────────────────────────
        FaceExercise(
            id: "jaw_drop",
            name: "Jaw drop hold",
            zone: .jaw,
            muscle: "Masseter muscle",
            instruction: "Drop your jaw as low as it will go — open as wide as possible. Hold.",
            tip: "Let gravity help — don't force it, just let the jaw fall naturally open.",
            emoji: "😱",
            holdSeconds: 5,
            threshold: DetectionThreshold(jawOpennessMin: 0.78)
        ),
        FaceExercise(
            id: "jaw_clench",
            name: "Jaw clench release",
            zone: .jaw,
            muscle: "Masseter muscle",
            instruction: "Clench your jaw tightly for 3 seconds, then drop it open completely. Repeat.",
            tip: "Feel the tension in your masseter muscle — then the relief when you release.",
            emoji: "😤",
            holdSeconds: 3,
            threshold: DetectionThreshold(jawOpennessMax: 0.1)
        ),

        // ── NECK ──────────────────────────────────────────
        FaceExercise(
            id: "chin_up",
            name: "Chin lift",
            zone: .neck,
            muscle: "Platysma muscle",
            instruction: "Tilt your head back slowly and push your chin forward and upward. Hold.",
            tip: "You should feel a stretch down the front of your neck — that's the Platysma working.",
            emoji: "🙂",
            holdSeconds: 5,
            threshold: DetectionThreshold(jawOpennessMin: 0.1)
        ),
        FaceExercise(
            id: "eyebrow_raise",
            name: "Eyebrow raise",
            zone: .neck,
            muscle: "Frontalis muscle",
            instruction: "Raise both eyebrows as high as you can toward your hairline and hold.",
            tip: "Keep the rest of your face completely still — only the eyebrows should move.",
            emoji: "🙆",
            holdSeconds: 4,
            threshold: DetectionThreshold(browRaiseMin: 0.72)
        ),
    ]

    static func exercises(for zone: FaceZone) -> [FaceExercise] {
        all.filter { $0.zone == zone }
    }
}

// MARK: — Face reading (published by FaceDetectionService)

struct FaceReading {
    var jawOpenness:   Float = 0
    var eyeOpen:       Float = 0   // average of left + right
    var smileAmount:   Float = 0
    var browRaise:     Float = 0
    var mouthOpenness: Float = 0
    var faceDetected:  Bool  = false
}

// MARK: — Session mode

enum SessionMode {
    case zone(FaceZone)
    case full

    var exercises: [FaceExercise] {
        switch self {
        case .zone(let z): return FaceExercise.exercises(for: z)
        case .full:        return FaceExercise.all
        }
    }

    var title: String {
        switch self {
        case .zone(let z): return z.rawValue
        case .full:        return "Full session"
        }
    }

    var durationLabel: String {
        switch self {
        case .zone: return "~4 min"
        case .full: return "~15 min"
        }
    }
}
