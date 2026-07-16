# Shipping Uncorked to Android (and keeping it in sync with iOS)

This repo now holds **both** implementations of Uncorked in one place:

| Platform | Lives in | Ships via |
|---|---|---|
| **iOS** | `App/` — native SwiftUI | GitHub Actions → TestFlight (`README-SHIP.md`, unchanged) |
| **Android** | `web/` — a web app wrapped by **Capacitor** | `gradlew assembleDebug` → APK, built locally on Windows |

They do **not** share runtime code (SwiftUI can't run in a WebView, and vice-versa).
Instead they conform to one shared source of truth in **`contracts/`**, and a drift
checker tells you when one platform has fallen behind the other. This is the
"chatbot edits once, both ship" seam.

---

## TL;DR — build the APK

Prereqs (already present on this machine): **JDK 17**, **Android SDK**
(`C:\Users\shave\AppData\Local\Android\Sdk`), **Node 20+**.

```powershell
cd C:\Users\shave\Documents\Claude\Projects\FLowTier   # (or this worktree)
npm install                      # first time only — installs Capacitor + tools
npx cap sync android             # copy web/ into the android project
cd android
./gradlew assembleDebug          # -> android/app/build/outputs/apk/debug/app-debug.apk
```

The APK is an **unsigned debug build** for sideloading (enable "Install unknown
apps" on the phone, copy the `.apk` over, tap it). That's all you need to put it
on your own device. A Play-Store release needs a signed **release** build — see
"Play Store" below.

> **Capacitor is pinned to v6** on purpose. Capacitor **7 and 8 require JDK 21**;
> this machine has JDK 17, and v6 is the last major that builds on 17. A WebView
> wrapping static assets needs nothing from 7/8. To move to v8 later: install a
> JDK 21, point Gradle at it (`org.gradle.java.home` in `android/gradle.properties`
> or `JAVA_HOME`), then `npm i @capacitor/{core,cli,android}@8 && npx cap sync`.

---

## The app itself (`web/`)

A **no-build** web app: native ES modules + a few vendored global scripts. There
is deliberately **no bundler and no CDN** so it runs fully offline inside the
Capacitor WebView.

```
web/
  index.html            loads vendor globals, then app.js as a module
  app.js                the shell: store wiring, tab nav, overlay host, theming,
                        and the one-prop SCREEN CONTRACT every screen follows
  core/                 the ported logic (mirrors App/Core/*)
    models.js           Flow/Mood/Symptom/Discharge/Phase + DayLog shape
    engine.js           cycle predictor — a faithful port of CycleEngine.swift
    store.js            state + localStorage persistence (key `flowtear.state.v1`)
    sampleData.js       first-launch demo seed (port of loadSampleData)
    dates.js, format.js helpers
    rewards.js          petals economy (port of RewardsStore.swift)
    stretchLibrary.js   stretch plans/moves (port of StretchLibrary.swift)
    version.js          the contracts version this web build is synced to
  screens/              one file per screen (Today, Calendar, Log, Insights,
                        Stretch, StretchSession, Garden, ThemeEditor, PhaseDetail)
  styles/               tokens.css (design tokens) + app.css (shell layout)
  vendor/               React, ReactDOM, htm, lucide icons, the design-system
                        component bundle, fonts — all offline
```

To work on the web app in a normal browser (ES modules need http://, not file://):

```powershell
python -m http.server 5178 --directory web    # then open http://127.0.0.1:5178
```

Design-system components self-inject their own CSS and only need the token
variables, so restyling is a `contracts/tokens.json` + `web/styles/tokens.css`
change, nothing per-screen.

---

## The shared source of truth (`contracts/`) + drift detection

```
contracts/
  manifest.json        contractsVersion + which files back each platform
  tokens.json          design tokens (both tokens.css and Theme.swift mirror this)
  cycle-vectors.json   golden input->output vectors for the predictor
```

Each platform stamps the contracts version it was last synced to:
`web/core/version.js` and `App/Core/ContractsVersion.swift`.

**Check whether a platform is an outdated version:**

```powershell
npm run check:parity
```

It reports:
1. **Version stamps** — flags iOS or web if its stamp is behind `contractsVersion`
   ("web is BEHIND — built against v1.0.0, contracts at v1.1.0").
2. **Algorithm** — re-runs the web engine against `cycle-vectors.json` and fails
   if it drifted from the golden spec.
3. **Models** — checks the Flow/Discharge enums still match across both platforms.

It exits non-zero on real drift, so you can gate a commit or CI on it.

---

## The "edit once, ship both" workflow

When you (or a chatbot) change something that both platforms share:

1. **Change the behavior in one conceptual place.**
   - Cycle math → `web/core/engine.js` **and** `App/Core/CycleEngine.swift`
     (then `npm run gen:vectors` to refresh the golden vectors).
   - A color/spacing token → `contracts/tokens.json`, `web/styles/tokens.css`,
     and `App/Design/Theme.swift`.
   - A logged-data field → `web/core/models.js` **and** `App/Core/CycleModels.swift`.
2. **Bump `contractsVersion`** in `contracts/manifest.json`, and the matching
   stamp in the platform(s) you touched (`web/core/version.js` /
   `App/Core/ContractsVersion.swift`).
3. **`npm run check:parity`** — it turns red until both sides are updated, so a
   half-finished change (web done, iOS forgotten) can't silently ship.
4. Ship each platform its own way: iOS via the TestFlight workflow, Android via
   `gradlew assembleDebug` (or a signed release build).

Pure UI/screen work only touches that platform's view file (`web/screens/*.js`
or `App/Views/*.swift`) and doesn't need a contracts bump.

---

## Icons & splash

Generated from the iOS app icon (`App/Assets.xcassets/.../AppIcon-1024.png`,
copied to `assets/logo.png`):

```powershell
npx @capacitor/assets generate --android \
  --iconBackgroundColor "#FDF2F7" --splashBackgroundColor "#FDF2F7" \
  --splashBackgroundColorDark "#2A0E1A"
```

Re-run after changing `assets/logo.png`. Output lands in
`android/app/src/main/res/` (regenerable, safe to delete).

---

## Play Store (later)

The steps above make a **debug** APK — perfect for sideloading onto your own
phone today. For a public Play-Store release you additionally need:
- a **signed release** build (`gradlew assembleRelease` with a keystore, or an
  `.aab` via `bundleRelease`),
- an upload key kept out of git (see `.gitignore`),
- a Play Console listing.

None of that is required to test the app on a device. Keep the keystore secret,
exactly like the iOS signing material in `README-SHIP.md`.
