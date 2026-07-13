# Flowtier Design System

**Flowtier** is a menstrual-cycle tracker with the warmth of a close friend and the polish of a modern app. It carries the brand voice and visual DNA of the **Bloom Calculator** — girly, soft, rose-pink, endlessly customizable — and applies it to a full, **Clue-class cycle tracker where nothing is behind a paywall**: flow tracking, symptoms, moods, pain, cycle & fertility predictions, charts, and fully customizable reminders are all free.

> The tagline: **bloom with your body.**

This folder is a working design system. A compiler indexes the tokens in `styles.css`, bundles the React components under `window.FlowtierDesignSystem_6b3d0d`, and renders every `@dsCard`-tagged HTML file on the **Design System** tab. Consumers link one file — `styles.css` — and read components off the namespace.

---

## Sources

Flowtier's **brand** is derived from the Bloom Calculator; its **feature set and screen vocabulary** are grounded in three open-source period trackers. Nothing here is a copy of any one product — the brand is Bloom's, the features are the union of what these trackers offer for free.

- **Bloom Calculator** — attached codebase at `BloomCalculator/` (SwiftUI). The source of the entire visual language: the rose palette & four theme presets (`BloomCalculator/contracts/theme-tokens.md`, `App/Theme/ThemeStore.swift`), the Quicksand / Playfair / Great Vibes type roles (`App/Theme/Fonts.swift`), the flower logo geometry (`App/Components/FlowerLogo.swift`), the card & shadow system (`App/Components/Card.swift`), the capsule tabs (`App/Components/KTabBar.swift`), the flower toast (`App/Views/Overlays/ToastHost.swift`), and the petal/glitter/shimmer motion language.
- **Menstrudel** — https://github.com/J-shw/Menstrudel (Flutter). Feature map, screen inventory, and domain vocabulary: flow rates (`spotting / light / medium / heavy`), pain levels, the 11 built-in symptoms, the notification/reminder taxonomy, and the insights charts (flow & pain breakdowns, symptom frequency).
- **peri** — https://github.com/IraSoro/peri (Ionic/React). Cycle math & phase model: ovulation ≈ 14 days before the next period, the fertile window, "chance of getting pregnant", and the days-until-period / delay language (`info/CALCULATION.md`, `src/state/CalculationLogics.ts`).
- **PeriodTracker** — https://github.com/samyak2403/PeriodTracker — provided as an additional reference. The two trackers above drove the domain design; explore this one to extend or cross-check feature coverage.

The reader is encouraged to open these repositories to build richer, more accurate Flowtier designs — they hold the real screens, edge cases, and calculations behind the surface recreated here.

---

## Content fundamentals

Flowtier's copy sounds like a **warm, unflappable friend who happens to know your cycle** — Bloom's affection, made appropriate for a health app you use every day.

- **Person & address.** Second person, always. Talk **to** "you"; the app is the quiet helper, never "I". Warm direct address is welcome — *"Good morning, love"*, *"you're on day 14"*.
- **Tone.** Gentle, encouraging, never clinical and never alarmist. A late period is a *"gentle heads-up"*, not an alert. Hard days get grace: *"However today feels, you're doing beautifully."*
- **Casing.** Sentence case everywhere — buttons, headings, labels. Never ALL-CAPS shouting; the only uppercase is the tiny tracked micro-label (`letter-spacing: --tracking-label`) over a group of controls.
- **Vocabulary.** Soft, bloom-themed where it's natural: a predicted period is your **"next bloom"**; the app helps you **"bloom with your body"**. But medical terms stay precise where precision matters — *ovulation, fertile window, luteal phase, flow, cramps*. Never coy or euphemistic about the body.
- **Length.** Short. One idea per line. Predictions and reminders are a single sentence.
- **Emoji.** **No emoji in product UI.** Bloom expresses delight through motion (petals, glitter, a flower that twirls), not emoji — Flowtier follows suit. Iconography is line icons, never emoji.
- **Punctuation.** Em-dashes and the occasional ellipsis for a soft, spoken rhythm. Exclamation points are rare and earned.

**Examples**

| Context | Copy |
|---|---|
| Greeting | Good morning, love — you're on day 14. |
| Prediction | Your next bloom is in 6 days. |
| Reminder | Gentle heads-up: your period's due in 2 days. |
| Empty state | Nothing logged yet — tap the bloom to start. No pressure. |
| Confirmation | Logged, love. Medium flow saved to today. |
| Affirmation | However today feels, you're doing beautifully. |

---

## Visual foundations

**Overall vibe.** Soft, rosy, and tactile — full-bleed pale-pink pages, white cards floating on warm rose shadows, generous rounded corners, and one signature flower. It should feel like a keepsake, not a dashboard.

- **Color.** A single rose family does almost everything (see the Colors cards). Page background is a barely-there pink (`--bg #FDF2F7`); cards are pure white. Pink climbs from `--primary` (petals) through `--primary-strong` (actions) to `--deep` (headlines). Text is a deep plum (`--text #421527`), never pure black. One gold accent (`--flower-center`) and one green (`--good`) are the only non-rose colors. **Four theme presets** ship — Cherry (default), Rose, Peony, Soft — swapped with `data-theme` on `<html>`; the app also exposes a custom-color editor in the spirit of Bloom's 12 editable tokens.
- **Cycle & flow color.** Two purpose-built ramps extend the palette: the **cycle-phase** ramp (menstrual rose → follicular pink → fertile gold → ovulation amber → luteal orchid) and the **flow-intensity** ramp (spotting → light → medium → heavy). These are the only place warmer non-pink hues (gold, orchid) appear, and they always mean something.
- **Type.** Three roles, no more. **Quicksand** (rounded, friendly) for all UI and body; **Playfair Display** for headings and — crucially — every big **numeral** (the cycle-day count, stats, countdowns), which gives the app its elegant editorial feel; **Great Vibes** script for the wordmark and rare affectionate moments (splash, welcome). Numerals are tabular.
- **Spacing & layout.** A soft 4px rhythm. Phone-first, single content column capped at `--screen-max` (440px), comfortably padded. Cards stack with 24px gaps. Minimum tap target 44px.
- **Corners.** Everything is round. Cards use `--radius` (22px); inner panels 12–16px; buttons, chips, tabs and switches are full pills (`--radius-pill`). Nothing in Flowtier has a sharp corner.
- **Cards.** White surface, 22px radius, and a **soft rose-tinted drop shadow** (`--shadow-card` / `--sh-2`), never a hard grey one and never a border by default. `soft`/`accent` variants are shadowless tinted panels for nesting; `outline` swaps the shadow for a hairline `--line` border.
- **Shadows.** A three-step ladder (`--sh-1`, `--sh-2`, `--sh-3`) all tinted with the theme's `--shadow` (a translucent deep-rose), so elevation feels warm. Buttons carry their own soft colored shadow.
- **Backgrounds.** No photography. Pages are flat pale pink; the splash/onboarding uses a **radial gradient** from `--surface-soft` at the top into `--bg`. Decoration is procedural — falling **petals**, **glitter** bursts on delightful taps, and a slow **shimmer** — never stock imagery or heavy gradients.
- **Motion.** Gentle and springy. One signature entrance easing, `cubic-bezier(.22,1,.36,1)` (`--ease-signature`), for views and cards fading up ~8px. Taps use a soft spring (`--spring`) with a slight overshoot. Loops (petals, shimmer, a breathing flower) are decorative and **always gated on `prefers-reduced-motion`** — durations collapse to near-zero under reduced motion. Progress bars and rings animate their fill with the signature ease.
- **Hover.** Fills lighten (soft controls mix ~24% primary in), primary buttons brighten slightly and lift their shadow, ghost controls pick up a soft-pink wash. Cards marked interactive lift `-2px`.
- **Press.** Everything shrinks — buttons/chips to `scale(.96)`, icon buttons to `.92` — echoing Bloom's keypad. Active fills deepen.
- **Focus.** A 3px `--focus-ring` (strong-pink mixed toward transparent) with a 2px offset, on `:focus-visible` only.
- **Borders.** Sparingly. Hairlines use `--line` (a pale rose), for list dividers and the `outline` card/`Chip` rest state. Selected chips and the ovulation day use a 1.5–2px colored border.
- **Transparency & blur.** Reserved for overlays: modal/sheet scrims use `--scrim` (deep-rose at ~28%) and may frost with `--blur-md`. Soft phase washes on the calendar are the `--phase-*-soft` tints, not opacity tricks.
- **Imagery vibe.** If real imagery is ever added it should be warm, soft-focus, and rosy — but the default brand is illustration-free: the flower mark and petals carry all the personality.

---

## Iconography

- **Set.** [**Lucide**](https://lucide.dev) — rounded, 2px line icons — is Flowtier's icon system, loaded from CDN (`https://cdn.jsdelivr.net/npm/lucide@0.469.0`). Its friendly stroke matches Quicksand's roundness. Icons inherit `currentColor` (usually `--deep` or `--primary-strong`) and size to ~18–26px. See the **Iconography** card in the Brand group.
  - **Substitution flag.** The source apps use platform icon sets not available on the web — Bloom uses Apple SF Symbols, Menstrudel uses Material Icons, peri uses Ionicons. Lucide is the closest cross-platform match (same rounded line style) and is used throughout this system. If you need pixel-exact parity with a specific source screen, swap in that platform's set.
- **Symptom icons.** `SymptomChip` / the `SYMPTOMS` export carries a recommended Lucide glyph per built-in symptom (cramps → `zap`, insomnia → `moon`, low mood → `cloud-rain`, …) so pickers, charts and legends stay consistent.
- **The flower.** The **FlowerMark** is not an icon — it's the brand mark, a procedural rose recreated from Bloom's `FlowerLogo`. Use it as the logo, empty-state flourish, and loading indicator. Do not substitute a flower glyph from the icon set for it.
- **No emoji, no unicode glyph icons.** Flow intensity uses a purpose-built droplet SVG (in `FlowScale`); everything else is Lucide.

---

## Logo & assets

Flowtier has **no dedicated logo image asset** — none was provided, and none is invented. The identity is the **Wordmark** (the name in Playfair, or Great Vibes for splash) locked up with the **FlowerMark** bloom. Render the wordmark wherever a logo would go. The Bloom Calculator's own app icon and the reference apps' marks are *their* brands and are deliberately not reused here.

There are therefore no raster assets in `assets/`; all brand visuals (flower, petals, droplets, gradients) are procedural SVG/CSS driven by tokens, and all icons come from the Lucide CDN.

**Fonts** load from the Google Fonts CDN (`tokens/fonts.css`) — the exact same three families the Bloom Calculator requests, so this is not a substitution. To ship fully offline, drop the OFL `.ttf` files into `assets/fonts/` and replace the `@import` with local `@font-face` rules; the tokens don't change.

---

## Components

Reusable React primitives, bundled under `window.FlowtierDesignSystem_6b3d0d`. Each lives in `components/<group>/` with a `.jsx`, a `.d.ts` (props + usage), a `.prompt.md`, and a group `@dsCard` HTML.

**Brand** (`components/brand/`)
- **FlowerMark** — the procedural bloom; the logo mark, empty-state flourish & loader.
- **FlowtierLogo** — the smiling pink clock brand mark (app icon, splash, Today header).
- **Wordmark** — the Flowtier name in brand type with the mark (this lockup is the logo).
- **Toast** — the flower-headed notice for saves, reminders & confirmations.
- **PetalRain** — the signature magical layer of drifting rose petals (splash, Today hero, celebrations).

**Core** (`components/core/`)
- **Button** — the primary action pill (primary / deep / soft / ghost; sm/md/lg; icons).
- **IconButton** — round icon-only tap target.
- **Card** — the fundamental surface (plain / soft / accent / outline; interactive).
- **Chip** — a selectable pill for moods, tags, filters.
- **Badge** — a small soft-tinted status label with optional dot.
- **SegmentedTabs** — the capsule tab switcher (from Bloom's KTabBar).
- **Switch** — the settings/reminder toggle.
- **ListRow** — a settings / reminders row (icon + title/subtitle + trailing control).

**Tracking** (`components/tracking/`) — the period-tracker domain
- **CycleRing** — the hero cycle visualization (phase arcs + today knob; `phaseForDay` helper).
- **PhaseBadge** — the prominent current-phase indicator.
- **FlowScale** — the flow-intensity selector (spotting → heavy droplets; `FLOW_LEVELS`).
- **SymptomChip** — a selectable chip bound to the built-in symptom set (`SYMPTOMS`).
- **DayCell** — one calendar day (period / predicted / fertile / ovulation / today / flow dot).
- **StatTile** — a compact stat panel for the Insights summary.
- **IntensityBar** — a labeled bar for breakdown charts (flow, pain, symptom frequency).

---

## UI kits

Full, interactive product recreations composed from the components above.

- **Flowtier app** — `ui_kits/flowtier_app/` — a phone-framed, click-through cycle tracker: **Today** (cycle ring, prediction, quick log), **Calendar** (month view with phase washes), **Insights** (charts & stats), **Log** (flow / symptoms / mood / pain sheet), and **Reminders** (customizable notifications + theme). Open `ui_kits/flowtier_app/index.html`.

---

## Repository index

```
styles.css                     ← the one file consumers link (@import manifest)
tokens/
  fonts.css                    Google Fonts import (Quicksand · Playfair · Great Vibes)
  colors.css                   palette, 4 theme presets, cycle-phase & flow ramps, aliases
  typography.css               font roles, type scale, weights, tracking
  spacing.css                  spacing scale, radii, layout
  effects.css                  shadow ladder, ring, blur, motion tokens & keyframes
components/
  brand/                       FlowerMark · Wordmark · Toast (+ brand.card.html)
  core/                        Button · IconButton · Card · Chip · Badge · SegmentedTabs · Switch · ListRow
  tracking/                    CycleRing · PhaseBadge · FlowScale · SymptomChip · DayCell · StatTile · IntensityBar
guidelines/                    foundation + motion specimen cards (Colors · Type · Spacing · Brand · Animations)
ui_kits/flowtier_app/          interactive app recreation (index.html + screens)
SKILL.md                       Agent-Skills manifest for reuse in Claude Code
readme.md                      this file
```

Generated by the compiler (do not edit): `_ds_bundle.js`, `_ds_manifest.json`, `_adherence.oxlintrc.json`.
