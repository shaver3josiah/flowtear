# Flowtier Design System — component cheat-sheet

Every component below is a React function component exposed on the global
namespace **`window.FlowtierDesignSystem_6b3d0d`** by `web/vendor/ds-bundle.js`
(copied verbatim from `design-system/_ds_bundle.js`).

## Load order (required)

The bundle is a plain global script that calls `React.createElement` internally,
so **React must be on `window` before ds-bundle.js runs**:

```html
<script src="./vendor/react.production.min.js"></script>      <!-- window.React -->
<script src="./vendor/react-dom.production.min.js"></script>  <!-- window.ReactDOM -->
<script src="./vendor/htm.js"></script>                        <!-- window.htm (optional, for tagged-template JSX) -->
<script src="./vendor/ds-bundle.js"></script>                  <!-- populates window.FlowtierDesignSystem_6b3d0d -->
```

`web/vendor/icon.js` (ES module) also reads `window.React`, so import it only
after the React script tag has run. Any load errors are pushed to
`window.FlowtierDesignSystem_6b3d0d.__errors`.

Usage:

```js
const DS = window.FlowtierDesignSystem_6b3d0d;
const html = window.htm.bind(window.React.createElement);
// html`<${DS.Button} variant="primary">Log today<//>`
// or window.React.createElement(DS.Button, { variant: "primary" }, "Log today")
```

Props extend the natural DOM element attributes (className, style, onClick, …)
unless noted. All types below are TypeScript-style shorthand; `?` = optional.

---

## brand — mark, wordmark, notices

### FlowerMark
The signature Flowtier bloom (procedural rose + gold center). Logo mark, empty-state flourish, or loading spinner.
- `size?: number` — width/height px (default 48)
- `spin?: boolean` — slow forever-rotate (decorative)
- `breathe?: boolean` — gentle scale-breathing loop (loading/ambient)
- `title?: string` — a11y label (default "Flowtier")

### FlowtierLogo
The brand mark: a smiling pink alarm clock. App icon, splash, onboarding hero.
- `size?: number` — width/height px (default 96)
- `title?: string` — a11y label (default "Flowtier")

### PetalRain
The "magical" layer: soft rose petals drifting down. Drop inside a `position:relative/absolute` parent; fills it, ignores pointer events, renders nothing under reduced-motion.
- `count?: number` — petals at once (default 14)
- `zIndex?: number` — stacking order (default 0)

### Toast
Flower-headed notice card (bloom mark + deep title + muted message). Saves, reminders, confirmations. No timer — mount/unmount it yourself.
- `title?: string` — bold deep headline
- `message?: string` — muted supporting line (truncates)
- `icon?: ReactNode` — replace the leading FlowerMark

### Wordmark
The Flowtier name in brand type with the bloom mark (Flowtier has no image logo — this lockup IS the logo).
- `variant?: "display" | "script"` — Playfair lockup vs Great Vibes flourish (default "display")
- `size?: number` — text size px, mark scales with it (default 28)
- `showMark?: boolean` — show FlowerMark before text (default true)
- `text?: string` — override the word (default "Flowtier")

---

## core — buttons, inputs, surfaces

### Badge
Small soft-tinted status label (optional leading dot). Inline status like "Day 3", "Predicted". For the larger phase pill use PhaseBadge.
- `tone?: "neutral" | "menstrual" | "follicular" | "fertile" | "ovulation" | "luteal" | "good"` (default "neutral")
- `dot?: boolean` — leading tone-colored dot

### Button
The primary action pill: full-capsule radius, springy press, themed shadow.
- `variant?: "primary" | "deep" | "soft" | "ghost"` (default "primary")
- `size?: "sm" | "md" | "lg"` — default "md" (46px)
- `block?: boolean` — stretch to container width
- `iconLeft?: ReactNode`, `iconRight?: ReactNode` — icon before/after label

### Card
The fundamental surface: white, soft themed shadow, 22px corners. Everything sits on cards.
- `variant?: "plain" | "soft" | "accent" | "outline"` (default "plain")
- `interactive?: boolean` — hover lift + pointer for tappable cards
- `as?: keyof JSX.IntrinsicElements` — render as another element ("button", "a", "section")
- `padding?: number | string` — override 18px interior padding

### Chip
Selectable pill for multi-select vocabularies (moods, tags). Toggle button (`aria-pressed`); drive `selected` yourself. For the built-in symptom set use SymptomChip.
- `selected?: boolean` — filled strong-pink state
- `size?: "sm" | "md"` (default "md")
- `icon?: ReactNode` — leading icon

### IconButton
Round, icon-only tap target for toolbars, calendar nav, close/overflow. Always pass `label`.
- `variant?: "soft" | "ghost" | "primary"` (default "soft")
- `size?: "sm" | "md" | "lg"` — default "md" (44px, min tap target)
- `label?: string` — a11y label (required for icon-only)
- `children?: ReactNode` — the icon node

### ListRow
Settings/reminders row: rounded leading icon, title + subtitle, trailing control. Stack inside a Card. Becomes a button (hover) when `onClick` set.
- `icon?: ReactNode` — leading icon (in a soft rounded square)
- `title?: ReactNode`, `subtitle?: ReactNode`
- `trailing?: ReactNode` — a Switch, chevron, or value text
- `onClick?: MouseEventHandler` — makes the row a button

### SegmentedTabs
Capsule tab switcher (soft track, strong-pink active pill). In-page view switching (Week/Month, Insights ranges). **Controlled.**
- `options: (SegmentOption | string)[]` — `SegmentOption = { value: string; label: string; icon?: ReactNode }`
- `value: string` — selected value (controlled)
- `onChange?: (value: string) => void`
- `block?: boolean` — fill width, equal-width segments

### Switch
Settings/reminder toggle (soft track fills strong-pink when on). **Controlled.** Commonly the ListRow trailing control.
- `checked?: boolean` — on/off (controlled)
- `onChange?: (next: boolean) => void`
- `label?: string` — a11y label

---

## tracking — cycle, flow, symptoms, charts

### CycleRing
The hero cycle visualization: soft donut with bleed days, fertile window & ovulation in phase colors, knob on today. Derives fertile/ovulation via the 14-day-luteal model.
- `cycleDay?: number` — current day, 1-based
- `cycleLength?: number` — avg cycle days (default 28)
- `periodLength?: number` — avg bleed days (default 5)
- `size?: number` — diameter px (default 260)
- `spinnable?: boolean` — drag/inertial fidget-spin (off under reduced-motion)
- `children?: ReactNode` — custom center content (overrides day/phase readout)

### DayCell
One day in the month calendar: state wash + today ring + selection + optional flow dot. Lay 7-wide in a CSS grid.
- `day: number` — day-of-month
- `state?: "period" | "predicted" | "fertile" | "ovulation" | null`
- `flow?: FlowLevel | "none" | null` — draws a small intensity dot
- `today?: boolean`, `selected?: boolean`, `muted?: boolean` (out-of-month dim)
- `size?: number` — diameter px (default 40)
- `onClick?: MouseEventHandler` — makes the cell a button

### FlowScale
Period flow selector: four droplets deepening spotting→heavy (`--flow-*` ramp). Single-select, tap-to-toggle. Centerpiece of the daily log sheet.
- `value?: FlowLevel | null` — `FlowLevel = "spotting" | "light" | "medium" | "heavy"`
- `onChange?: (level: FlowLevel | null) => void` — null when the current level is re-tapped
- `block?: boolean` — full-width equal cells (default true)

### IntensityBar
Labeled horizontal bar for breakdown charts (flow-by-day, pain, symptom frequency). Stack in a Card for an insights chart.
- `label: ReactNode` — row label
- `value?: number` — fill fraction 0–1
- `color?: string` — fill color (default primary); pass a `--flow-*` / `--phase-*` token
- `meta?: ReactNode` — right-aligned meta ("6 days", "42%")

### PhaseBadge
Prominent current-phase indicator: phase-tinted pill + color dot + name + optional subtitle. Today header, top of log sheet. For tiny inline status use Badge.
- `phase?: CyclePhase` — `"menstrual" | "follicular" | "fertile" | "ovulation" | "luteal"` (default "follicular")
- `subtitle?: ReactNode` — trailing detail ("Day 3", "2 days left")

### StatTile
Compact stat panel (big Playfair value + muted label). Grid for the Insights summary.
- `value: ReactNode` — headline value (Playfair)
- `unit?: string` — small trailing unit ("days")
- `label: ReactNode` — muted caption
- `icon?: ReactNode` — icon above the value
- `tone?: "soft" | "accent" | "card"` (default "soft")

### SymptomChip
Selectable chip bound to the built-in symptom vocabulary. Wrap several for the log sheet.
- `symptom?: SymptomKey | string` — built-in key supplies the canonical label; `SymptomKey = "cramps" | "headache" | "bloating" | "fatigue" | "tenderBreasts" | "backPain" | "acne" | "moodSwings" | "nausea" | "insomnia" | "depressed"`
- `label?: string` — override/custom label
- `selected?: boolean` — controlled
- `onClick?: MouseEventHandler`
- `icon?: ReactNode` — leading icon (recommended: the Lucide glyph named in SYMPTOMS)
- `size?: "sm" | "md"` (default "md")

---

## Exported helpers & constants

On `window.FlowtierDesignSystem_6b3d0d`:

- **`FLOW_LEVELS`** — `{ key: FlowLevel; label: string; color: string; drop: number }[]` (from FlowScale). The ordered flow ramp with display labels and droplet sizes.
- **`SYMPTOMS`** — `{ key: SymptomKey; label: string; icon: string }[]` (from SymptomChip). The built-in symptom list with recommended Lucide icon names — pair `icon` with `web/vendor/icon.js`'s `Icon`.

**NOT exposed on the namespace** (present in the `.d.ts` but marked unexposed by the bundle):

- **`phaseForDay(day, cycleLength, periodLength): CyclePhase`** — documented in `CycleRing.d.ts` and used internally by CycleRing, but the bundle lists it under `unexposedExports`, so it is **not** a property of `window.FlowtierDesignSystem_6b3d0d`. If a screen needs phase-for-day logic, replicate the 14-day-luteal model or use `web/core/engine.js`'s `predict().phase`.
