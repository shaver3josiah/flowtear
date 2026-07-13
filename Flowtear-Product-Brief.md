# Flowtear — Product Brief

**Features · Critique of v0.1 · Tracking Categories · Wireframe IA**
_Synthesis of a 7-perspective analysis (code critique, features, taxonomy, wireframes, personas, domain guardrails, competitive) + a completeness-critic pass._

> **Name note:** the code/bundle is still `Flowtear` (`com.shaver.flowtear`) and the Today header hardcodes "Flowtear", but you're now calling it **Flowtear**. Reconcile before any submission and check name/trademark collisions — the "Flo/Flow" space is crowded. This brief uses *Flowtear*.

---

## 0. Contents
1. [Do this next (ranked)](#1-do-this-next-ranked)
2. [Critique of v0.1 — what's good, what's broken](#2-critique-of-v01)
3. [Tracking categories — the taxonomy (core wireframe input)](#3-tracking-categories--the-taxonomy)
4. [Wireframe screen inventory & IA](#4-wireframe-screen-inventory--ia)
5. [Personas & goal modes](#5-personas--goal-modes)
6. [Feature backlog by theme](#6-feature-backlog-by-theme)
7. [Domain guardrails (non-negotiables)](#7-domain-guardrails)
8. [Competitive positioning & the indie wedge](#8-competitive-positioning)
9. [Open decisions to lock before wireframing](#9-open-decisions-to-lock)

---

## 1. Do this next (ranked)

The one thing that must come **first**, before onboarding or any feature: **harden persistence.** Onboarding (real data flows in) and TestFlight model-iteration (fields get renamed/removed) are *exactly* what triggers a silent history wipe today. Lost cycle history is the only irreversible failure here.

| # | Priority | Why |
|---|----------|-----|
| 1 | **Harden persistence** — on decode failure *refuse to overwrite* the existing blob; decode enums leniently (drop unknown cases, don't fail the whole Snapshot); version the Snapshot; write a timestamped backup before each save | A single model change silently wipes every tester's history **and** clobbers the backup — triggered precisely by the TestFlight cadence you're about to start |
| 2 | **Onboarding that seeds real history** — HealthKit import as primary path, manual single-date as fallback | Unblocks the `hasHistory` dead-end (currently a DEBUG-only hack) and seeds accurate predictions day one |
| 3 | **Fix the engine correctness cluster** — exclude spotting from period-start; 21–45d plausibility band; clamp ovulation into `[periodEnd, next]`; explicit *late-by-N* state; future-date guard; median over mean | These bugs put predictions in the **past** or count "Day 90 / due now forever" — the first-screen moment every persona judges the app on |
| 4 | **"Not birth control" disclaimer + "estimate" framing everywhere fertility shows**; drop predictive *Avoid pregnancy* mode to logging/reminders only | The missing disclaimer is the single biggest liability and the App Store 1.4.1 probe; naive FAM-as-contraception is a regulatory + real-pregnancy trap for a solo indie |
| 5 | **Local notifications** (period-soon / late / fertile / log-nudge) with a one-tap "log flow" action on the notification | The core retention engine of the category; zero backend; the app currently leaks the exact users it predicts well for |
| 6 | **App lock (Face ID/passcode)** + move data off plaintext UserDefaults to a `FileProtection.complete` file excluded from iCloud backup + app-switcher blur | Reproductive data in a plist lands in unencrypted backups and is readable on an unlocked shared phone — post-Roe table stakes |
| 7 | **Resolve the Log IA + autosave contradiction** — one add-surface (center-+ sheet); discrete taps autosave, note field debounced; category on/off lives in *Manage Trackers*, not the daily scroll | Two perspectives specify conflicting log homes and a per-keystroke autosave that O(n)-rewrites all history — decide once or build the log screen twice |
| 8 | **Close the design-system seam** — tokenize radius/spacing/type scale; replace stringly-typed tokens with an enum (DEBUG-assert on miss); add a dark palette; drop forced `.light` and the `xLarge` Dynamic Type cap | The token seam is the app's stated premise, but radii/spacing/type are still literals and missing tokens render **invisibly** — importing the real system is a per-view edit unless this is closed first |

---

## 2. Critique of v0.1

### What's genuinely right (keep it)
- **CycleEngine is pure & deterministic** — injected `Calendar` + `today`, fully unit-tested (no-history, single/regular/irregular, phase, gap-split). The hardest thing to retrofit; you got it right.
- **Date math is DST/timezone-correct** — day counts use `dateComponents([.day])` over `startOfDay`, not `86400*n`. Logs keyed by gregorian `en_US_POSIX` `yyyy-MM-dd`. Most trackers get this wrong.
- **Empty history modeled at the engine** (`hasHistory=false` → all-nil) and honored by the UI — no fabricated predictions.
- **Zero dependencies**, clean composition (single `Card`, `@Observable` injected via `@Environment`), `isEmpty`-pruned store, DEBUG-only sample seed.

### Bugs & risks (prioritized)

| Severity | Area | Problem | Fix |
|---|---|---|---|
| **High** | Persistence data-loss | One Codable blob; on any decode failure `load()` silently empties, then `save()` overwrites the good data with nothing → **silent wipe + backup clobber** on any model change | Refuse-to-overwrite on decode failure; lenient enum decode; versioned Snapshot; timestamped pre-save backup; longer term SwiftData/per-day file |
| **High** | Prediction — spotting poisons model | `isPeriod = flow != nil`, so mid-cycle `spotting` opens a phantom period start → halves cycle length, wrecks ovulation/fertile/next | Detect starts from `light/medium/heavy` only (`flow.weight >= 2`); keep spotting as a calendar mark that doesn't feed math |
| **High** | Prediction — no sanity band | `averageCycleLength` only filters `d>0`; two starts 3 days apart → avg 3 → ovulation = `last−11` (**before** the cycle) | Ignore gaps outside ~21–45d; clamp avg to that band; clamp ovulation into `[periodEnd, next−1]` |
| **High** | Overdue / late never handled | `cycleDay` grows unbounded past `next`; ring pins 100%; UI says period due "now" forever; phase stuck `.luteal` | Add a `.late(byN)` state: "Late 3d", distinct ring tint, "Did it start?" quick action |
| **High** | Accessibility — color-only meaning, 0 VoiceOver labels | Calendar/flow/mood encode state by background color/opacity; **not one** `accessibilityLabel` in the codebase; fails WCAG "don't rely on color alone" | Label every cell/chip (+`.isSelected` trait); add a non-color channel (dot/glyph); label icon-only buttons |
| Med | Dynamic Type capped `xLarge`, dark mode force-disabled | Defeats Accessibility text sizes; leans on 9–11pt labels; `.preferredColorScheme(.light)` app-wide, no dark tokens | Remove cap (reflow), add dark token map, drop forced light |
| Med | Future dates loggable | Tapping a future calendar cell binds it in Log; DatePicker range doesn't cover the tapped-cell path | Guard the tap (read-only for future); engine ignores period days after `today` |
| Med | BBT is dead code | `temperatureC` exists but no input UI and the engine never reads it; no °C/°F toggle | Scope BBT to Conception mode (chart + coverline) or remove until real |
| Med | Data-model gaps | No sex/protection, cervical mucus, or OPK/pregnancy results; symptoms are binary (no severity); enums are closed (no custom) | Add mucus + sex + test results as first-class; 3-level symptom intensity; custom-tag escape hatch |
| Med | Autosave rewrites all history per keystroke | `note` `onChange` → re-encode entire Snapshot to UserDefaults | Debounce note (save-on-commit); discrete chips can stay immediate |
| Med | Calendar predicts only 1 cycle ahead | `cellFill` uses only the single next window; 2+ months forward shows nothing | Project N cycles forward per visible month |
| Med | Inconsistent contiguity | `periodStarts` splits on gap>2 but `averagePeriodLength` needs gap==1 → same data counted differently | Share one run-detection helper + threshold |
| Med | False confidence on thin data | 1 logged cycle → full predictions at 28-day fallback, shown like a year of data; mean is outlier-sensitive | "Still learning" state until ~2–3 cycles; median/trimmed mean; show variability (±N days) |
| Med | Touch targets < 44pt | Flow circles 34pt, chips ~30pt; flow levels differ only by 0.5 opacity | Pad to ≥44pt (`contentShape`); differentiate by size/fill/label |
| Med | **Seam not actually complete** | radii `12/14/20` are literals (only `Card` uses the token); no spacing tokens; type *scale* hard-coded at call sites; `theme.color("typo")` → `.clear` silently | Add radius/spacing/type tokens; enum tokens + DEBUG assert; `onPrimary`/`onFlow` tokens for white-on-fill text; primitive + semantic token tiers |
| Low | Force-unwrapped date math | `cal.date(byAdding:)!` in 5 places | Guard-let with fallback |

**Engine edge cases to add as tests:** overdue growth, mid-cycle spotting start, degenerate 3-day cycle, short-but-real (<19d) cycle with luteal 14 (ovulation before start), predicted-but-unlogged next period, single-cycle confidence, missed-log 56-day outlier, contiguity mismatch, future-dated bleed, single-bleeding-day 1-day average.

---

## 3. Tracking categories — the taxonomy

**The core wireframe input.** 24 categories, tiered. **Core** = always on. **Optional/Advanced** = off by default, user-enabled in *Manage Trackers*, so a first-run user sees ~5 cards and a TTC user flips "Fertility" on once.

| Category | Tier | Hideable | Input control | Key items |
|---|---|---|---|---|
| **Bleeding & Flow** | core | no | segmented (intensity) + chips (color/clots) | none/spotting/light/medium/heavy · color · clots · breakthrough · post-sex |
| **Pain** | core | no | chips (location) + slider/segmented (severity) | cramps, lower-back, ovulation (mittelschmerz), breast, headache, migraine · none→severe · painkiller-taken |
| **Physical Symptoms** | core | no | chips (multi) | bloating, tender breasts, fatigue, dizziness, hot flashes, swelling, fever, congestion |
| **Emotional & Mental** | core | no | chips + 1–5 face scale | happy/calm/sensitive/sad/irritable/angry/anxious/… · brain fog · overall mood & stress 1–5 |
| **Notes, Tags & Photos** | core | no | multiline + tag chips + photo | free note · reusable custom tags · photo · pin/flag |
| **Menstrual Products** | optional | yes | chips + stepper | pad/tampon/cup/disc/underwear · absorbency · change count · cup fill · leak |
| **Digestive & Gut** | optional | yes | chips | nausea, vomiting, diarrhea, constipation, gas, cramps, reflux |
| **Skin & Hair** | optional | yes | chips + optional photo | acne (+location), oily/dry, eczema, cold sore, hair shedding, brittle nails |
| **Energy & Fatigue** | optional | yes | segmented/slider + chips | 1–5 energy · afternoon crash · wired · sluggish |
| **Sleep** | optional | yes | stepper + segmented + time | hours · quality 1–5 · trouble falling asleep · night sweats · vivid dreams · bed/wake |
| **Sexual Activity, Libido & Protection** | optional | yes | toggle/stepper + chips + segmented | had sex/count · type · orgasm · libido 1–5 · protection · EC taken · painful/bleeding after |
| **Birth Control & Medication** | optional | yes | toggle+time + add-rows | BC type · pill-taken+time · placebo · missed/late · custom meds (name/dose/time) · pain relievers |
| **Supplements & Vitamins** | optional | yes | toggle chips + custom | prenatal, folic acid, iron, vit D, magnesium, omega-3, … + custom |
| **Appetite & Cravings** | optional | yes | segmented + chips | appetite low/normal/high · sweet/salty/carb cravings · emotional eating · aversions · thirst |
| **Exercise & Activity** | optional | yes | chips + segmented + stepper | walk/run/strength/yoga/… · intensity · duration · felt performance |
| **Hydration & Consumption** | optional | yes | tap-to-increment tallies | water · caffeine · alcohol · goal met |
| **Life Events & Context** | optional | yes | chips (+note) | travel/timezone · high stress · sick · big night · vaccination · appt · med change · fasting |
| **Cervical Mucus & Fluids** | advanced | yes | segmented + chips + note | dry/sticky/creamy/watery/egg-white · amount · sensation · **abnormal-discharge flag** |
| **Cervical Position** | advanced | yes | 3× segmented | height · firmness · opening |
| **Basal Body Temperature** | advanced | yes | decimal pad + time + segmented | temp (°C/°F) · time · method (oral/vaginal/wearable) · disturbed-sleep flag |
| **Ovulation & Pregnancy Tests** | advanced | yes | segmented + chips + photo | LH neg/low/high/peak · hCG neg/faint/pos · brand · time · strip photo |
| **Weight & Vitals** | advanced | yes | decimal pads | weight (kg/lb) · body temp · BP · resting HR · measurements |

**Log-screen organization (progressive disclosure, not one giant scroll):**
1. **Core always-on block** (top): Flow, Pain, Physical, Emotional, Notes — this is the *entire* screen for a period-only user. Flow intensity is the one required tap.
2. **"Your other trackers"**: only the optional/advanced categories the user enabled, each a collapsed card with a one-line summary + count ("Sleep · 7h, quality 4"). Expand inline — no navigation push.
3. **"+ Add more to track"** → *Manage Trackers*: all categories as toggles, grouped **Everyday / Wellness / Fertility / Personal**. Fertility + sensitive Personal categories **off by default**.
4. **Phase-aware surfacing**: on predicted-fertile days float enabled fertility trackers up; during the period float Products + Pain up. Reorders *enabled* categories only — never re-enables hidden ones.
5. **Fast paths**: recently-used/favorited chips sort first (real symptom set ≈ 6 items, not 40); search jumps to any category/item; one-tap presets ("Period day" pre-fills flow+product+cramps).
6. **Privacy**: sex/libido & any user-marked-private category can sit behind the app lock.

---

## 4. Wireframe screen inventory & IA

**Nav model:** tab root, **5 slots — Today · Calendar · center Log (+) · Insights · Me.** The current 4th *Log tab is deleted*; logging becomes a center-**+** sheet (matches Flo/Clue/Stardust). Each tab owns a `NavigationStack` for drill-downs. **Sheets** for finish-and-dismiss tasks (Quick-Log, Full Log/Edit, Predictions adjust, Manage Trackers, Paywall, permission primers). **Full-screen covers above the tab bar** for App Lock (launch + resume) and Onboarding (first run). **One add-surface reached three ways:** center-+, Today quick-log card, Calendar day-tap — all open the *same* pre-dated Quick-Log sheet.

**Onboarding (12 steps, resumable):** Welcome → **Goal select** → **Privacy promise** (real screen, not fine print) → last-period date → typical period length → typical cycle length (+"not sure") → birth-control method → optional age/DOB → pick trackers → notifications primer → app-lock primer → summary showing the seeded first prediction. *(Add a HealthKit-import option at the date step — seeds real multi-cycle history and fixes cold-start + accuracy at once.)*

**Quick-Log fast path:** center-+ opens a bottom sheet defaulted to today; highest-frequency trackers as one-tap **autosaving** chips (reuse `toggleFlow`/`upsert`, no Save button). Period logged in **1 tap**; full mood+symptom entry in **≤5s**; "More…" expands into Full Log without losing input. Long-press the + writes today's flow without opening the sheet.

| Screen | Purpose | Key states |
|---|---|---|
| **App Lock** | Biometric/passcode gate before content; app-switcher blur | locked · authenticating · failed(shake) · disabled(passthrough) · biometric-unavailable |
| **Onboarding** | Convert first-open into a seeded cycle | first-run · in-progress · skipped · completed · resumable |
| **Today / Home** | One-glance status + one-tap log (absorbs the old Log tab) | empty · needs-more-data · populated · period-active · fertile-window · **overdue** · loading |
| **Phase / Cycle-Day Detail** | Tap the ring → explain phase (hormones, common now, personalized) | generic · personalized · loading |
| **Calendar (Month)** | Cycle over time: bleeding + predicted period + fertile + ovulation + per-day dots | empty · populated · predicted-only · **overdue (hollow "?" cell)** · loading |
| **Day Detail (read+edit)** | Full read of one day across categories; entry to edit | empty · populated · future-date · editing · error · deleted/undo |
| **Quick-Log Sheet** | 5-second capture, autosaving chips | today · editing-existing · saved(haptic) · expanded · error |
| **Full Log / Edit Day** | Comprehensive per-day tracking across every category | empty · partial · populated · autosaving · category-hidden · first-time primer |
| **Manage Trackers** | Show/hide + reorder categories; presets; custom tracker | default preset · customized · adding-custom · error |
| **Insights / Analytics** | Patterns + predictions with confidence | empty · needs-more-data · populated · low-confidence · flagged · premium-locked |
| **Cycle History (list)** | Ledger of past cycles (length, period length, variance flag) | empty · single-cycle · populated · anomaly-flagged |
| **Cycle Detail** | One past cycle day-by-day (flow/mood/symptom/BBT) | empty-partial · populated · in-progress · loading |
| **Symptom / Tracker Trend** | Tap any metric → frequency & timing across cycles | empty · sparse · populated |
| **Predictions Detail** | Explain predictions, confidence, the math; **adjust/correct** | confident · low-confidence · **overdue** · edited · loading |
| **BBT & Temperature Chart** | Coverline + thermal-shift + overlays (Conception mode) | empty · sparse · populated · shift-detected · error |
| **Reminders / Notifications** | Configure nudges + timing; pill reminder | not-requested · granted · denied(banner) · configured · off |
| **Settings / Me** | Hub: goal, cycle settings, trackers, reminders, privacy, data, learn, premium | default · edited · premium vs free |
| **Privacy & Security** | App lock, disguise/decoy, on-device statement, delete-all | lock-off · lock-on · setting-passcode · confirm-delete · deleted |
| **Data & Backup / Export** | Doctor PDF · CSV/JSON · encrypted backup · optional HealthKit | empty · ready · generating · share-sheet · error · restore-confirm |
| **Learn / Education** | Evergreen phase/symptom/condition content (bundled markdown) | browse · reading · searched-empty · offline-ok · premium-locked |
| **Paywall / Premium** | Gate *advanced* value, never core logging/prediction | default · plan-selected · purchasing · success · error · already-subscribed |
| **Goal / Mode Switch** | Switch intent; re-tune predictions/categories/copy | unchanged · switching · switched · mode-active |

---

## 5. Personas & goal modes

Eight personas collapse into **~4 shippable "shapes"** — a lightweight *presentation layer over ONE data model*, not 8 forked apps. Add one `enum Goal` to `CycleSettings` (already Codable in the blob) and gate presentation on it; storage stays identical, every persona writes the same `DayLog`.

| Persona | Goal | Lives in | Churns if… | Shape |
|---|---|---|---|---|
| **Maya — TTC** | Pinpoint & *confirm* ovulation, time intercourse | Fertility dashboard: fertile-days-left, BBT chart w/ coverline, 1-tap OPK/mucus | temp un-chartable, no mucus/OPK/sex fields (all true today) | **Conception** |
| **Renée — Avoiding** | Know which days are unsafe | Daily "open / use protection" verdict | app *implies* contraceptive reliability (liability!) | **Awareness — NOT birth control** (defer true FAM) |
| **Aisha — Cycle awareness** | Don't be caught off guard, 5-sec log | The Today ring already built | friction, noise, a visibly wrong prediction | **Simple (default)** |
| **Bex — PCOS/Endo/PMDD** | Manage a condition, walk into appointments with data | Symptom+severity log + trends to hand a clinician | no severity, no custom symptoms, no meds, no export; needs *daily* DRSP mood diary | **Health/Symptom** |
| **Diane — Perimenopause** | Make sense of erratic cycles; 12-month milestone | Symptom timeline + "days since last period" (NOT a fertility ring) | fertile-window ring is useless/insulting; no hot-flash/HRT; no red-flag bleeding logic | **Life-stage** |
| **Zoe — Teen/first period** | Learn what's normal, stay private | Friendly calendar + reassuring phase explainers | TTC framing, clinical tone, no lock, "irregular = error" | Simple + teen copy |
| **Sam — Athlete** | Sync training to phase | Phase + "today's training guidance" | no HealthKit/wearable ingestion | *Performance — defer* |
| **Priya — Chronic-condition correlation** | Correlate a personal metric with phase | Correlation/trends overlay | closed taxonomy, no custom trackables, no export | *needs custom-trackables data-model work* |

**Recommendation:** ship **Simple** (already ~90% built) as default; add **Conception** and **Health/Symptom** next (they drive the most retention + word-of-mouth). A mode reshapes, in impact order: (a) the Today **hero** (ring vs symptom-timeline vs days-since-period vs training); (b) *whether* ovulation/fertile is computed at all (hide for Diane/Zoe); (c) default log categories + order; (d) copy/tone; (e) red-flag rules. **Don't branch the data layer.** Two features genuinely need model work regardless of modes: **custom trackables + severity** (Priya/Bex) and a **real BBT chart** (Maya).

---

## 6. Feature backlog by theme

Condensed; value/effort in parens. Full detail lives in the workflow output.

- **Foundations (do first):** onboarding (H/S) · prediction confidence ranges (H/M) · late-period handling (H/S) · iCloud/export backup (H/L) · irregular-cycle detection (H/M) · correct/move a logged start (M/S) · restore a11y + dark (M/S).
- **Onboarding & personalization:** goal-mode switch (H/M) · adaptive Today card (H/M) · customizable quick-log (M/S) · reminder time & tone (M/S) · manual cycle/luteal overrides (M/S).
- **Fertility / TTC:** fertile-window + peak-day (H/M) · BBT chart + coverline (H/M) · OPK/LH logging that re-anchors ovulation (H/S) · cervical mucus (H/S) · intercourse/timing (H/S) · two-week-wait + test reminder (M/S) · pregnancy mode (M/L) · unified fertility score (M/M).
- **Contraception:** BC method tracking + reminders (H/M) · pill reminder + missed-dose card (H/S) · risky-day/FAM view *with loud disclaimer* (M/M) · protection-used log (M/S) · refill/re-supply + IUD/implant expiry (M/S).
- **Symptom & physical health:** expanded + custom symptoms (H/M) · flow volume & product tracking → menorrhagia flag (H/S) · pain severity 0–10 (H/S) · abnormality flags (H/M) · sleep/energy/libido scales (M/S) · weight/BBT trends (M/S) · med & supplement log (M/S).
- **Mood & mental health:** mood intensity + multiple/day (H/M) · **PMS/PMDD pattern detection** (H/M) · cycle-phase mood forecast (H/M) · guided journaling (M/S) · stress/anxiety scales (M/S).
- **Lifestyle:** water/caffeine/alcohol (M/S) · exercise + phase-based training (M/M) · sleep (M/M) · logging streaks (M/S) · phase self-care tips (M/M).
- **Perimenopause & life-stage:** perimenopause mode (H/M) · menopause symptom set (H/S) · cycle-change timeline (H/M) · HRT tracking (M/S) · postpartum/breastfeeding mode (M/M) · teen mode (M/M).
- **Medical & clinical export:** PDF cycle report (H/M) · CSV/JSON export (H/S) · appointment summary (M/S) · fertility-clinic export (M/M) · med-adherence report (M/S).
- **Engagement & retention:** local notifications (H/M) · home-screen widget (H/M) · Live Activity countdown (M/M) · daily nudge + streaks (M/S) · monthly recap (M/M) · Apple Watch quick-log (M/L) · predictive heads-up cards (M/S).
- **Platform integrations:** HealthKit two-way sync (H/M) · Siri/App Intents quick-log (M/M) · Watch app (M/L) · wearable temperature import (M/L) · calendar export (L/S) · Files/AirDrop backup (M/S).
- **Privacy & trust:** app lock (H/S) · local-only default, sync opt-in (H/S) · encrypted local storage (H/M) · no-account/no-analytics posture (H/S) · stealth/disguise mode (M/M) · panic wipe (M/S).
- **Education:** phase-based daily cards (M/M) · symptom explainers (M/S) · just-in-time tips (M/S) · Cycle 101 / first-period (L/S) · glossary tooltips (L/S).

**Top-10 overall:** onboarding · local notifications · late-period handling · export + PDF doctor report · app lock · confidence ranges + irregular honesty · goal modes · home-screen widget · HealthKit sync · OPK+mucus logging.

**Completeness-critic additions (nobody proposed these):**
- **Pregnancy trackables** (week, due-date countdown, kick counts, contraction timer, weight-gain curve) — the app claims a "pregnancy mode" with no data model behind it.
- **Postpartum**: lochia (clinically *not* a period start), breastfeeding/pumping, "return of menses" watch.
- **Pregnancy loss / miscarriage** — absent from all 7; emotionally critical for TTC, needs a sensitive path + tone.
- **Fertility-treatment (IVF/IUI)**: stim meds, trigger shot, retrieval/transfer dates, numeric beta-hCG trend — medicated cycles must *suspend* the calendar engine.
- **Urinary/bladder** (UTI, urgency, incontinence) — hallmark perimenopause signal.
- **Prediction feedback as input** — "was this right? / it started today / adjust start" so the user trains the model (cheapest accuracy lever for irregular cyclers).
- **Global search** across your own logged days/notes ("when did I last log a migraine?").
- **A data-recovery surface** — the scariest failure (silent wipe) currently has *no UI* to say "couldn't read your data — restore from backup."

---

## 7. Domain guardrails

**Privacy (the moat):** zero network calls today — keep it. Never add analytics/ads/attribution/crash SDKs that phone home cycle data. Move off plaintext `UserDefaults` (lands in unencrypted Finder/iCloud backups) to `FileProtection.complete`, excluded from backup. Add app-lock + app-switcher blur + neutral icon/name. Ship export + real delete-all. Free-text notes are the highest-risk field — never sync/log them off-device. Post-Roe threat model: no account, no server = nothing to subpoena. Add `PrivacyInfo.xcprivacy` now (UserDefaults reason `CA92.1`, `NSPrivacyTracking=false`). Write a plain-language privacy policy URL + first-run consent.

**Medical accuracy / liability:** everything is an **estimate** — label next-period & fertile window too, not just ovulation. **Never present the fertile window as contraception** — add "Not a birth-control method" copy near every fertile/ovulation display (currently 100% absent). Flag abnormal cycles (<21d, >35–45d, irregular, absent) with a gentle non-diagnostic "consider a clinician" note. Fix the late-period dead end. Persistent "for tracking & education, not medical advice" disclaimer at onboarding + Settings. Never diagnose or name conditions.

**Inclusivity:** ask the goal up front and let users hide *all* fertility content. Don't assume sexual activity, a partner, cis-female identity, or that pregnancy is wanted. Body-neutral copy; avoid "that time of the month." Support prediction-breaking life stages (BC, pregnancy, postpartum, perimenopause) with a "pause predictions" mode. Fahrenheit path for US (BBT is °C-only today). Define "luteal/follicular" on first use.

**Accessibility:** un-cap Dynamic Type; route sizes through text styles; VoiceOver label the ring ("Cycle day 14 of 28, fertile, next period ~Jul 20") and every calendar cell; add a non-color mark; audit `muted #8A6470` on `#FEF6F4` for AA; support dark; respect Reduce Motion; ≥44pt targets; label icon-only controls.

**App Store:** privacy policy URL mandatory; complete the privacy "nutrition label" honestly ("Data Not Collected" if true); `PrivacyInfo.xcprivacy`; guideline 1.4.1 probes the missing "not birth control" disclaimer; honest age rating; no contraception/medical claims in metadata; in-app delete expected; **reconcile the "Flowtear" string** before submission.

**Monetization (don't exploit anxiety):** keep core logging + period/cycle predictions **free**; never paywall safety (disclaimers, export, delete); no scary notifications, no gating "are you late?" content, no "unlock your fertility score" dark patterns. Sensible indie model: one-time lifetime unlock or modest sub for *advanced* extras (correlations, unlimited history, custom trackers, PDF export, extra themes, app-lock). No ads, ever. StoreKit 2. TestFlight is free — ship v1 fully free, design the paywall later.

---

## 8. Competitive positioning

**Table stakes (present in every app; ✅ = Flowtear already has):** flow intensity ✅ · core predictions ✅ · month calendar ✅ · broad symptoms + mood + notes + BBT ✅ · **cervical mucus ❌ (biggest single omission — in all 7 apps)** · **sexual activity ❌** · **notifications ❌** · onboarding ❌ · adjustable cycle length (partial) · OPK/pregnancy results ❌ · pill logging + reminder ❌ · **data export/backup ❌** · predictions as a range, not a hard date.

**What each competitor teaches:**
- **Clue** — *toggleable tracking categories* (pick which of ~20 show) + distinct modes (Conceive/Pregnancy/Perimenopause/Birth Control) + science-forward, non-pink, gender-neutral design. The credible "science + privacy" alternative.
- **Apple Cycle Tracking** — deliberately *retrospective* ovulation (dodges contraception liability), Cycle Deviation notifications, deep on-device HealthKit. The privacy gold standard you're implicitly compared against.
- **Natural Cycles** — FDA-cleared contraception; the prediction *is* the product (daily Red/Green); wearable BBT. Shows how far one well-modeled signal goes — and the regulatory bar you should *not* try to clear as an indie.
- **Flo** — huge symptom wheel, AI assistant, Anonymous Mode (post-FTC-settlement damage control). Privacy is a *repaired liability*, not a native strength.
- **Stardust** — astrology/moon-phase identity alone drove installs; proves an aesthetic wedge — but its privacy *story* outran its implementation (a cautionary tale).
- **Ovia / Glow** — deep TTC charting; both carry data-sharing/breach baggage (employer model; past vulns) — the opposite of an on-device story.

**The indie wedge:** *radical, provable privacy + honest, non-manipulative design* — a lane the incumbents structurally can't occupy (all account/cloud/ad/data-monetized; even Clue & NC paywall core predictions). Flowtear is already on-device with no accounts. Ship **privacy + honesty as the brand**, **irregular-cycle / perimenopause support as the audience** (28-day/TTC-tuned apps serve them badly), and **honest symptom↔cycle correlation insights** ("migraines cluster in your late luteal phase") **as the retention hook** — a natural feature for the existing pure `CycleEngine` that competitors bury behind paywalls or don't compute at all.

---

## 9. Open decisions to lock

Resolve these *before* drawing wireframes so screens aren't built twice:

1. **Log home** — center-+ sheet (recommended, matches Flo/Clue) **vs** a rich Log destination tab. Pick one; category management follows it.
2. **Autosave** — resolve as: discrete chip taps autosave immediately; the free-text note is debounced/save-on-commit. Not "autosave everything" (that O(n)-rewrites all history per keystroke).
3. **Contraception** — BC logging + reminders **yes**; predictive "Avoid" mode **cut or relabelled "awareness, not birth control."** Do not ship FAM-as-contraception.
4. **Persistence direction** — local `FileProtection.complete` file (excluded from backup) **first**; opt-in E2E sync much later. `NSUbiquitousKeyValueStore` is *not* privacy-grade and caps ~1MB.
5. **Canonical goal-mode set** — pick one list (recommend: Simple / Conception / Health / Life-stage; defer Performance + true contraception) so the Goal switch has a fixed target.
6. **BBT** — scope to Conception mode (chart + coverline), so it's neither dead code nor a v1 obligation.
7. **Name** — commit to Flowtear (or not) and reconcile the in-app string + bundle id.

---

_Generated from a 7-perspective + completeness-critic analysis. Raw per-perspective output retained in the session transcript if deeper detail on any section is needed._
