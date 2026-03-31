import SwiftUI
import Combine

@MainActor
final class FaceTrainerViewModel: ObservableObject {

    // MARK: — Screen state
    enum Screen { case picker, calibrating, exercise, rest, complete }
    @Published var screen: Screen = .picker

    // MARK: — Exercise state
    @Published var exercises:        [FaceExercise] = []
    @Published var exerciseIndex:    Int            = 0
    @Published var holdProgress:     Double         = 0      // 0 → 1
    @Published var isDetected:       Bool           = false
    @Published var secondsRemaining: Int            = 0
    @Published var restCountdown:    Int            = 3

    // MARK: — Session complete
    @Published var feedbackText:  String = ""
    @Published var isLoadingFeedback: Bool = false
    @Published var sessionDuration: TimeInterval = 0

    // MARK: — Dependencies
    let detector = FaceDetectionService()
    private let claude = ClaudeService()

    // MARK: — Timers & tracking
    private var holdTimer:     AnyCancellable?
    private var restTimer:     AnyCancellable?
    private var sessionTimer:  AnyCancellable?
    private var sessionStart:  Date = .now
    private var detectionCancellable: AnyCancellable?
    private var holdAccumulator: Double = 0
    private var zonesCompleted: Set<String> = []

    // MARK: — Computed

    var currentExercise: FaceExercise? {
        guard exerciseIndex < exercises.count else { return nil }
        return exercises[exerciseIndex]
    }

    var totalExercises: Int { exercises.count }

    var progressFraction: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(exerciseIndex) / Double(totalExercises)
    }

    // MARK: — Start session

    func startSession(mode: SessionMode) {
        exercises        = mode.exercises
        exerciseIndex    = 0
        holdProgress     = 0
        holdAccumulator  = 0
        zonesCompleted   = []
        sessionStart     = .now
        screen           = .calibrating

        detector.start()

        // Give Vision 2 seconds to calibrate baseline
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.beginExercise()
        }
    }

    // MARK: — Exercise flow

    private func beginExercise() {
        guard let ex = currentExercise else { complete(); return }
        holdProgress    = 0
        holdAccumulator = 0
        isDetected      = false
        secondsRemaining = ex.holdSeconds
        zonesCompleted.insert(ex.zone.rawValue)
        screen = .exercise
        startDetectionLoop()
    }

    private func startDetectionLoop() {
        holdTimer?.cancel()
        holdTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard let ex = currentExercise,
              screen == .exercise else { return }

        let detected = ex.threshold.isMet(by: detector.reading)
            && detector.reading.faceDetected

        isDetected = detected

        if detected {
            holdAccumulator += 0.1
            holdProgress     = min(1.0, holdAccumulator / Double(ex.holdSeconds))
            secondsRemaining = max(0, ex.holdSeconds - Int(holdAccumulator))

            if holdAccumulator >= Double(ex.holdSeconds) {
                exerciseComplete()
            }
        } else {
            // Reset if face leaves position
            if holdAccumulator > 0 {
                holdAccumulator = max(0, holdAccumulator - 0.2) // gentle decay
                holdProgress    = holdAccumulator / Double(ex.holdSeconds)
            }
        }
    }

    private func exerciseComplete() {
        holdTimer?.cancel()
        holdProgress = 1.0

        // Brief success pause then rest
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.startRest()
        }
    }

    private func startRest() {
        screen        = .rest
        restCountdown = 3
        restTimer?.cancel()
        restTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.restCountdown > 1 {
                    self.restCountdown -= 1
                } else {
                    self.restTimer?.cancel()
                    self.exerciseIndex += 1
                    if self.exerciseIndex < self.exercises.count {
                        self.beginExercise()
                    } else {
                        self.complete()
                    }
                }
            }
    }

    // MARK: — Session complete

    private func complete() {
        holdTimer?.cancel()
        restTimer?.cancel()
        detector.stop()
        sessionDuration = Date().timeIntervalSince(sessionStart)
        screen = .complete
        Task { await fetchFeedback() }
    }

    private func fetchFeedback() async {
        isLoadingFeedback = true
        let zones     = zonesCompleted.joined(separator: ", ")
        let count     = exercises.count
        let minutes   = Int(sessionDuration / 60)
        let prompt    = "The user just completed \(count) facial exercises targeting: \(zones). Session time: \(minutes) minutes."
        let system    = """
        You are Glow, a warm companion app. Give exactly 2 sentences:
        1. A fun, specific celebration of what they just did (mention a zone they trained).
        2. A motivating fact about facial exercises and wellbeing.
        Be warm, encouraging, and teen-friendly. No clinical language.
        """
        feedbackText = (try? await claude.quick(prompt: prompt, system: system))
            ?? "Amazing work — your face just got a real workout! Regular facial exercises can ease tension headaches and help you feel more relaxed in your body."
        isLoadingFeedback = false
    }

    // MARK: — Reset

    func reset() {
        holdTimer?.cancel()
        restTimer?.cancel()
        detector.stop()
        exercises        = []
        exerciseIndex    = 0
        holdProgress     = 0
        holdAccumulator  = 0
        isDetected       = false
        feedbackText     = ""
        screen           = .picker
    }
}
