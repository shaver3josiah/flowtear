# Garden Editor — roadmap

A Wix-style, local-only admin panel for Uncorked that edits the app's art
(Posey, the ten blooms, the cycle ring) and each screen's layout boxes, then
ships the result through the existing gates to TestFlight. No backend, no AI,
no Mac. Everything below is grounded in a verified research pass (19 external
sources, 11 codebase findings, July 2026) and sized honestly.

## The one decision everything hangs on

Uncorked has **no image assets to swap**. `App/Assets.xcassets` holds only the
app icon and two colors; every bloom, the ring, Posey, and the stick-figure
poses are procedural Swift drawing code (`FlowerArt.swift`, `FlowerMark.swift`,
`CycleRing.swift`, `PoseFigure.swift`, `CoachFlower.swift`). So a "replace the
graphics" panel has exactly three possible levers:

1. **Edit the drawing code** — rejected: that's a code editor, not a panel.
2. **Runtime-interpreted recipe data** — chosen: the drawings already compose
   from four shared primitives (`petalRing`, `dot`, `arc`, `sparkle` at
   `FlowerArt.swift:49-124`), so each bloom is a short list of calls with
   numeric args and hex colors. That serializes to JSON without inventing
   anything. Prior art: this is the sections-vs-layout split from Airbnb's
   Ghost Platform and the schema-versioned component trees of
   `bipa-app/swiftui-json-render` (v0.2.1, Mar 2026) and `0xWDG/DynamicUI`
   (v0.0.9, Jun 2026), applied to art instead of screens.
3. **Code generation from shared source** — deferred: the repo already does
   this once (`web/vendor/ds-bundle.js` is generated); a second generator is
   Phase 3 leverage, not Phase 0 necessity.

The same lens applies to layout: screens are hardcoded VStack stacks today
(`TodayView.swift:82-101`, `InsightsView.swift:29-64`), and the smallest
schema that gives an editor something safe to edit is **an ordered array of
section ids per screen** — native section implementations stay in Swift, the
JSON only picks presence and order. Insights already wants this: the
report-card promotion rule is evaluated in two places (`InsightsView.swift:37`
and `:55`) and would collapse into ordering-as-data.

## Tool verdicts from research (so we don't relitigate)

| Tool | Verdict | Why |
|---|---|---|
| Puck v0.22 (MIT, React) | **Optional adopt** for the layout tab | Emits JSON, runs local, active (Jul 2026). A hand-rolled reorder list may be enough; Puck is the upgrade path. |
| swiftui-json-render / DynamicUI | **Blueprint, not dependency** | Copy the schemaVersion + unknown-component-fallback design; both are pre-1.0. |
| DivKit (Yandex) | **Reject as dependency** | Production-grade but UIKit-backed and enormous for one app; steal schema ideas only. |
| Judo | **Reject** | macOS app; this project exists because there is no Mac. |
| Rive / dotLottie | **Phase 3 only, eyes open** | Gorgeous animated-Posey path, but .riv authoring needs Rive's cloud editor — conflicts with local-only. dotLottie's iOS player is current (v0.16.4, Jul 2026) if ever wanted. |
| Onlook / tweakcn / GrapesJS / Webstudio | **Pattern references** | Local-first editor ergonomics worth imitating; none fit as-is. |

## Phase 0 — Externalize the seams (the unglamorous prerequisite)

**Goal:** the app renders identically, but art and layout come from data.

- **P0.0, before anything else:** prove the shipping mechanism. Confirm
  `project.yml`'s resource globs carry `contracts/*.json` into the .ipa on
  the XcodeGen CI runner (one throwaway tagged build reading one test value),
  and add a CI step validating the JSON against its schema so a bad edit
  fails the build, not the phone. If this doesn't hold, everything below is
  a plan for files the app never sees — settle it first.
- `contracts/art-recipes.json` v1: the ten bloom recipes (lists of
  petalRing/dot/arc/sparkle steps), FlowerMark's three-ring table
  (`FlowerMark.swift:37-41` is already a struct array), and a shared
  ring-constants blob (trackRadius 84/200, stroke 15, snapBand 26 — today
  duplicated across `CycleRing.swift:226`, its inline PhaseArc copy, and
  `web/components/ringSticker.js:23-26`).
- `contracts/layout.json` v1: ordered section-id arrays for Today, Insights,
  Log. Each existing card becomes a case in a small section registry per
  screen. LogView's per-section descriptors (icon/title/tint at
  `LogView.swift:33-129`) are the template.
- PoseFigure's ten poses (`PoseFigure.swift:74-143`) are already command
  lists in unit space — near-free to externalize; do it last as the proof the
  schema generalizes.
- Every file carries `schemaVersion` + a defined fallback (unknown step →
  skip and log; malformed file → bundled default). This is the
  swiftui-json-render pattern. Fallback covers unknown fields only:
  a *semantic* schema change (renaming or reinterpreting a field) ships a
  migrator in the panel that rewrites her existing files on first open —
  old configs are never silently reinterpreted.
- **Parity ritual:** these are new shared-truth contracts. Manifest gains
  `art-recipes` and `layout-config` features, contractsVersion bumps to
  1.5.0, both platform stamps follow, web mirrors read the same JSON (the
  bloom recipes finally give web the FlowerArt port it never had).
Effort, stated with the humility it deserves: nobody has converted even one
bloom yet, so all sizing is a guess until the daisy is done. Convert the
daisy first, measure, then re-estimate the other nine. Working guess: the
bulk of the project. Exit test: `git diff` on a recipe changes a flower on
both platforms with no Swift edit.

## Phase 1 — The Garden Editor panel (local web, extends the cockpit)

**Goal:** `npm run cockpit` grows an **Editor** tab at localhost:4499.

Same zero-dependency Node pattern as `tools/cockpit/server.mjs` (it already
proved the shape: local server, git-aware, gates before ship).

- **Blooms:** pick a bloom → sliders and steppers for each recipe step
  (petal count, offset, length, width, style, startAngle) + color wells →
  live preview rendered by the **web parity mirrors themselves**, not a
  reimplementation. The drift-checked JS ports are the preview engine; that
  is the honest answer to preview fidelity on a Mac-less machine, and a
  golden-SVG snapshot test pins panel-preview and web-render together.
- **Posey:** FlowerMark ring-table editor (same control style) plus
  CoachFlower's proportion literals (offsets at `CoachFlower.swift:171-199`,
  crown arc constants that exist twice) surfaced as one "proportions" sheet.
- **Ring:** thickness/radius/sheen from the shared constants blob, with the
  phase arcs previewed across all eight theme presets (colors keep flowing
  through `Theme.swift` tokens — the panel extends that seam, never forks it).
- **Layout:** per-screen drag-to-reorder list of section cards with
  show/hide. Hand-rolled first; Puck if it ever needs nesting.
- Every save writes the contracts JSON and shows a plain `git diff` preview.

Effort: re-estimate after Phase 0's daisy calibration; the panel skeleton
reuses the cockpit's proven shape, so the risk lives in the preview wiring,
not the chrome. Exit test: change the daisy's petal count in the panel, see
it live in the preview, and find the exact same change in `git diff`.

## Phase 2 — Publish, preview, and the device loop

**Goal:** edit → see it → ship it, with the gates unskippable.

- **Publish** = the cockpit's existing release path: tests + `check:parity`
  (now also schema validation) must be green, then commit → tag → push →
  TestFlight. The panel gets a "Ship this look" button that calls the same
  endpoint; nothing new to trust.
- **Device preview reality:** with no Mac there is no simulator; TestFlight
  is the only true device render (~5 min CI + processing). Mitigations, in
  order: the web preview (Phase 1), the PWA build on an Android device or
  browser reading the same JSON instantly, and an optional CI job that
  renders recipe SVGs as artifacts on every push. Accept the loop; don't
  pretend it away.
- **App Store position:** configs ship inside the bundle via CI, reviewed
  with every build — squarely fine under Guideline 2.5.2. The panel must
  never grow a "fetch configs at runtime" feature; that line is the line.
- **Eyes before shipping:** gates catch broken, not ugly. The ship screen
  (F8) must show a rendered before/after strip of every changed surface,
  and publishing requires having seen it. A hideous flower that passes
  every test is still a hideous flower on a stranger's phone.

Exit test for Phase 2: one full loop — edit a petal, ship through the gates,
see it on the TestFlight build — completed and timed, so the real cost of
the no-Mac preview loop is a measured number, not a vibe.

## Phase 3 — Leverage (only after 0-2 hold)

- Pose editor (the command-list schema already supports it).
- Animated Posey via Rive/dotLottie **if** the cloud-editor tradeoff is ever
  acceptable; revisit local .riv tooling maturity then.
- Codegen option: emit Swift constant tables from the JSON at build time to
  claw back any render cost, if profiling ever shows one.
- Color Studio unification: fold the panel's color wells and the in-app
  Color Studio into one token surface.

## Figma flow (frame-by-frame, ready to generate)

The Figma connector isn't authorized in this environment, so the flow ships
two ways: the clickable prototype at `tools/cockpit/editor-prototype.html`
(open it in any browser) and this frame list, which one message can turn into
a real Figma file once the connector is connected.

1. **F1 Cockpit home** — existing four cards + new "Garden Editor" card.
2. **F2 Editor home** — four surface tiles (Blooms · Posey · Ring · Layout),
   each with a live thumbnail and "last edited" from git.
3. **F3 Bloom gallery** — ten blooms on the shelf, rarity badges, edited-dot.
4. **F4 Bloom editor** — left: layer list (ring/dot/arc/sparkle steps);
   center: large live preview on bg/surface/dark swatches; right: parameter
   inspector for the selected step; footer: reset · save · diff.
5. **F5 Posey editor** — ring-table rows + proportions sheet + crown preview.
6. **F6 Ring editor** — radius/thickness/sheen sliders, eight-preset strip.
7. **F7 Layout editor** — screen picker (Today/Insights/Log), draggable
   section list with visibility eyes, phone-frame preview.
8. **F8 Review & ship** — rendered before/after strip of every changed
   surface, git diff panel, gate checklist (tests · parity · schema),
   version field, "Ship this look" primary (disabled until the strip has
   been seen).
9. **F9 Shipped** — CI run status, TestFlight processing note, petal rain.

## What this roadmap refuses to promise

- Pixel-identical panel preview and SwiftUI render: browsers and SwiftUI
  Canvas rasterize differently. The web-mirror preview + golden tests bound
  the drift; they do not erase it.
- Remote config or hot-swapping art on shipped phones. Everything rides a
  git tag through review, or it doesn't ride.
- That Phase 0 is quick. Externalizing ten hand-drawn blooms without
  changing a pixel is careful work, and it is most of the project. The
  panel is the reward, not the work.
