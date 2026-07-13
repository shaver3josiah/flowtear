# Flowtear

A period & cycle tracker for iOS (SwiftUI, iOS 17+). Logs bleeding, mood, and
symptoms; predicts the next period, fertile window, and ovulation from your own
history. Built to accept a design system by swapping a single file.

## Build

Same no-Mac toolchain as BloomCalculator (XcodeGen + CI macOS runner).

```bash
xcodegen generate          # produces Flowtear.xcodeproj from project.yml
open Flowtear.xcodeproj     # or build on a macOS CI runner
```

Bundle id: `com.shaver.flowtear`. Tests: `FlowtearTests` (cycle-engine coverage).

## Layout

```
App/
  FlowtearApp.swift      app entry + RootView (tab shell)
  Design/Theme.swift     ← THE DESIGN SYSTEM SEAM (see below)
  Core/
    CycleModels.swift    Flow / Mood / Symptom / DayLog / settings
    CycleEngine.swift    pure prediction math (unit-tested)
    CycleStore.swift     @Observable state + UserDefaults persistence
  Components/            Card, tab bar, FlowLayout (wrapping chips)
  Views/                 Today (cycle ring), Calendar, Log, Insights
Tests/CycleEngineTests.swift
```

## Design-system seam — how the incoming system plugs in

**Every color, font, radius, and spacing value in the app resolves through
`Theme` (`App/Design/Theme.swift`). No view hardcodes a hex or a font.** So the
design system integrates in one place:

1. **Colors** → replace the values in `Theme.tokens`. Keep the token *names*
   (`primary`, `flow`, `fertile`, `surface`, …) and the whole app re-skins. If
   the system ships JSON/Style-Dictionary tokens, decode them to `[String:String]`
   and pass to `Theme(tokens:)` — no view changes.
2. **Fonts** → set `FFFont.bodyFamily` / `FFFont.displayFamily` to the bundled
   families and add the `.ttf`s under `UIAppFonts` in `project.yml`. `ffBody` /
   `ffDisplay` route everywhere.
3. **Radius/spacing** → `radius` is already a token; add more numeric tokens and
   read them via `theme.metric("name", fallback)`.

Token vocabulary intentionally mirrors BloomCalculator (`bg`, `surface`,
`surfaceSoft`, `primary`, `primaryStrong`, `deep`, `text`, `muted`, `line`) plus
domain tokens (`flow`, `flowSoft`, `fertile`, `ovulation`, `predicted`,
`luteal`), so a shared design system carries over cleanly.

Current values are **placeholders** picked to resemble the reference app — expect
to overwrite them.

---

## Brainstorm — where to take it next

Ranked by value-to-effort, not exhaustively built. The engine + seam already
support most of these with small additions.

### Highest-value tracking to add
- **Predictions confidence / irregular-cycle flag** — when cycle-length variance
  is high, show a range ("period likely Jul 27–31") instead of a false-precise
  date. The engine already computes per-cycle gaps; surfacing variance is a small
  step and is the single most trust-building feature for a predictor.
- **Symptom ↔ phase correlation** — "you log cramps most on cycle days 1–2",
  "headaches cluster in your luteal phase." Insights already tallies symptoms;
  bucketing them by cycle day is the payoff that makes daily logging worth it.
- **BBT / cervical-mucus logging** (`temperatureC` field already exists) for
  users tracking fertility more seriously — a temperature chart with a coverline
  confirms ovulation retrospectively.
- **Late-period / pregnancy-mode awareness** — if a predicted period is N days
  late, soften language and offer a "could be pregnant / testing" state rather
  than silently drifting predictions.
- **Birth-control tracking** — pill/patch/ring reminders and a "protected" flag
  that changes fertile-window messaging (don't imply a fertile window is safe or
  risky without knowing method).

### Highest-value UX abilities
- **Home-screen & Lock-screen widgets** (WidgetKit) — cycle day + days-to-period
  at a glance is the #1 reason these apps get opened; a widget is the retention
  hook.
- **Notifications** — "period likely tomorrow", "fertile window opens in 2 days",
  gentle daily log nudge. Local notifications, no server needed.
- **Apple Health sync** (HealthKit) — read/write menstruation, BBT, and symptoms
  so Flowtear plays with the rest of the ecosystem. Two-way, opt-in.
- **Discreet / privacy mode** — Face ID lock, neutral app icon + name option.
  A period app is sensitive data; this is table stakes for many users.
- **Cycle history scroll** — a vertical ribbon of past cycles (length, period
  length, flagged irregularities) for spotting long-term trends.
- **Partner / share mode** — optional read-only share of "period is coming"
  without exposing symptom detail.

### Things to get *right*, not just build
- **Predictions are estimates** — never present ovulation or a "safe" day as
  fact; label everything "estimated," especially anything touching contraception.
- **Data ownership & privacy** — all data is on-device (`UserDefaults` today;
  move to a file/DB when volume grows). Any cloud sync must be explicit, opt-in,
  and ideally end-to-end encrypted. State this plainly in-app.
- **Inclusive, non-judgmental copy** — works for someone tracking to conceive,
  to avoid, for health, or for perimenopause. Avoid assuming intent.

### Deferred on purpose (add when asked)
- Cloud sync / account system — on-device is enough for v1; add when multi-device
  is a real need.
- Community / content feed — big surface, unrelated to core tracking.
- Watch app — the widget covers the glanceable need first.

_Persistence note:_ v1 stores everything in one `UserDefaults` blob — fine for
years of daily logs. If it ever gets heavy, `CycleStore.save/load` is the only
place to swap in a file store or SwiftData; nothing else changes.
