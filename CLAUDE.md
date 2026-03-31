# Glow — Claude Code Instructions

## What is Glow?
Glow is a mental health companion iOS app for teens and young adults.
It uses the Anthropic Claude API (claude-sonnet-4-6) for all AI features.
Built in SwiftUI, targeting iOS 17+.

## Project structure
```
Glow/
├── App/
│   ├── GlowApp.swift          — @main entry point, routes onboarding vs home
│   └── AppState.swift         — Global ObservableObject (name, mood, streak, resources)
├── Models/
│   └── Models.swift           — Message, MoodEntry, Mood, LocalResource
├── Services/
│   ├── ClaudeService.swift    — POST to Anthropic API, returns response string
│   ├── SAMHSAService.swift    — Fetches local mental health resources by lat/lng
│   ├── LocationService.swift  — CoreLocation wrapper, publishes coordinate + cityName
│   └── SystemPromptBuilder.swift — Builds system prompt from user context + resources
├── Views/
│   ├── Home/
│   │   └── HomeView.swift     — Dashboard + tab bar, 9 feature cards in 3 sections
│   ├── Chat/
│   │   ├── ChatView.swift     — Main Glow AI companion chat UI
│   │   └── ChatViewModel.swift— Wires ClaudeService + location + SAMHSA + prompt builder
│   ├── Sleep/
│   │   └── SleepView.swift    — Wind-down routines, sleep sounds, Claude bedtime story
│   ├── SocialCoach/
│   │   └── SocialCoachView.swift — AI role-play practice for difficult conversations
│   ├── ThoughtRefresh/
│   │   └── ThoughtRefreshView.swift — CBT-based negative thought flip tool
│   ├── Wins/
│   │   └── WinsView.swift     — Daily gratitude + celebrate small victories journal
│   ├── BodyCheck/
│   │   └── BodyCheckView.swift— Body scan, tension/energy/hunger awareness tool
│   ├── Focus/
│   │   └── FocusView.swift    — Study anxiety, Pomodoro timer, exam stress tool
│   ├── Breathe/
│   │   └── BreatheView.swift  — Animated breathing orb, box/478/coherence patterns
│   ├── Move/
│   │   └── MoveView.swift     — Yoga + simple movement, mood-based routine picker
│   └── Onboarding/
│       └── OnboardingView.swift — Name, age, location permission, first check-in
└── Resources/
    └── Secrets.plist          — ANTHROPIC_API_KEY (git-ignored)
```

## Brand & design
- Primary color: GlowAmber = #EF9F27 (warm amber)
- Secondary color: Teal = system teal for calm/crisis moments
- Typography: SF Pro (system font), rounded where possible
- Tone: warm friend, never clinical, never preachy
- Crisis button (988) always visible in chat header

## Features to build — in priority order

### 1. HomeView (DONE — update navigation links)
Three sections:
- Talk & reflect: Glow chat, Thought refresh, Social coach, Wins
- Move & breathe: Breath trainer, Yoga & movement
- Daily tools: Sleep, Body check, Focus help
- Crisis bar: I need help now → calls 988

### 2. SleepView (BUILD THIS FIRST)
- Wind-down mode selector: breathing, body scan, story, sounds
- Claude generates a personalised 2-minute bedtime story based on user's mood
- Simple ambient sound buttons: rain, white noise, ocean
- Soft purple colour scheme (#7F77DD family)
- Timer: 10, 20, 30 min sleep timer

### 3. ThoughtRefreshView (BUILD SECOND)
- User types a negative thought
- Claude responds with: what's the thought pattern, a gentler reframe, one action
- Keep it conversational not clinical — "here's another way to see that"
- 3-step UI: Write thought → See refresh → Save or try again
- Teal colour scheme

### 4. SocialCoachView (BUILD THIRD)
- User picks a scenario: friend conflict, saying no, talking to a parent, asking for help
- Claude role-plays as the other person
- User practises what to say, Claude gives gentle feedback after
- Purple colour scheme

### 5. WinsView (BUILD FOURTH)
- Daily 3-win prompt: big win, small win, something you're grateful for
- Saved locally with SwiftData
- Claude adds a warm one-line celebration response to each entry
- Amber colour scheme, star motif

### 6. BodyCheckView (BUILD FIFTH)
- Body scan: tap where you feel tension on a simple body outline
- Sliders for energy (1-10), hunger (1-10), tiredness (1-10)
- Claude interprets the combination and suggests one thing to try
- Coral colour scheme

### 7. FocusView (BUILD SIXTH)
- Pomodoro-style timer: 25 min focus, 5 min break
- Pre-session: Claude asks what you're working on + gives a 1-line motivation
- Post-session: Claude checks in on how it went
- Amber colour scheme, clock motif

## Claude API usage guidelines
- Model: claude-sonnet-4-6
- Max tokens: 512 for chat, 256 for short responses (wins, body check)
- Always pass system prompt from SystemPromptBuilder
- Never hardcode API key — always read from Secrets.plist
- All API calls are async/await with proper error handling

## Safety rules (enforce in every system prompt)
- Never diagnose
- Never prescribe medication
- Always surface 988 if crisis detected
- Never invent local resource names or phone numbers
- Anger handled conversationally in main chat — no separate anger feature

## Colors (Assets.xcassets)
- GlowAmber: light #EF9F27 / dark #FAC775
- Add these as needed per feature view

## What NOT to do
- No gender-specific language or design
- No toxic positivity
- No clinical/therapy language
- No separate anger feature (handled in chat)
- Never break Glow's warm companion persona
