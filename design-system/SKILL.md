---
name: flowtier-design
description: Use this skill to generate well-branded interfaces and assets for Flowtier — a girly-but-modern, fully customizable menstrual-cycle tracker — for production or throwaway prototypes/mocks. Contains essential design guidelines, colors, type, fonts, cycle & flow tokens, and UI kit components for prototyping period-tracking experiences (cycle rings, calendars, flow/symptom logging, predictions, insights, reminders).
user-invocable: true
---

Read the `readme.md` file within this skill first — it is the full design guide (content voice, visual foundations, iconography, and the component + UI-kit index). Then explore the other files as needed:

- `styles.css` + `tokens/` — the token system (palette & 4 theme presets, cycle-phase & flow ramps, type, spacing, radii, shadow, motion). Link `styles.css` to inherit everything.
- `components/` — reusable React primitives (brand: FlowerMark, Wordmark, Toast, PetalRain; core: Button, IconButton, Card, Chip, Badge, SegmentedTabs, Switch, ListRow; tracking: CycleRing, PhaseBadge, FlowScale, SymptomChip, DayCell, StatTile, IntensityBar). Each has a `.prompt.md` with usage.
- `guidelines/` — foundation specimen cards (Colors, Type, Spacing, Brand) plus an **Animations** group (petal rain, bloom & twirl, glitter, shimmer) you can view for exact values.
- `ui_kits/flowtier_app/` — a full interactive app recreation to copy screens/patterns from.

If creating visual artifacts (slides, mocks, throwaway prototypes), copy the assets you need out and produce static HTML files for the user to view — link `styles.css`, load icons from the Lucide CDN, and either mount the compiled components from `_ds_bundle.js` (`window.FlowtierDesignSystem_6b3d0d`) or lift the exact token values into your own markup. If working on production code, copy the tokens and read the rules here to become an expert in designing with this brand.

Design principles to honor: warm second-person copy (never clinical), sentence case, no emoji; a single rose palette with purposeful cycle-phase & flow color; Quicksand for UI, Playfair for headings & numerals, Great Vibes for the wordmark; fully rounded corners, soft rose-tinted shadows, gentle springy motion (always respecting `prefers-reduced-motion`); Lucide line icons; the procedural FlowerMark as the logo (there is no logo image asset).

If the user invokes this skill without other guidance, ask them what they want to build or design, ask a few clarifying questions (surface, audience, which cycle features, light/theme preset), and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.
