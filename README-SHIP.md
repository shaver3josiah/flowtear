# Shipping Flowtear to TestFlight (no Mac)

This repo builds, signs, and uploads Flowtear to TestFlight entirely on a GitHub
Actions **macOS runner**. You never touch a Mac.

Signing uses **fastlane match**: one Apple Distribution certificate + App Store
provisioning profile are created once and stored, encrypted, in a private `flowtear-certs`
repo. Every build fetches them read-only — so the runner never creates a new certificate
and the account **certificate cap is never hit again** (and the same cert can be shared
with Bloom). See §1.5 to bootstrap it once.

Pipeline: `.github/workflows/testflight.yml` → select newest Xcode →
`xcodegen generate` → `fastlane beta` (`match` fetch → `build_app` → `pilot`) → TestFlight.

The build number comes from `github.run_number`, so every upload gets a unique, increasing
build number automatically.

---

## 0. This folder is not a git repo yet

Nothing here is under version control. Before anything can run, turn it into a repo and
push it to GitHub:

```powershell
cd C:\Users\shave\Documents\Claude\Projects\FLowTier
git init -b main
git add -A
git commit -m "Initial Flowtear commit"
gh repo create flowtear --private --source . --remote origin --push
# or: git remote add origin https://github.com/<you>/flowtear.git ; git push -u origin main
```

---

## 1. Apple-side one-time setup

Do this once, as the **Account Holder**. Getting the API key role wrong is the #1 cause
of a run that dies minutes in.

1. **Accept all agreements** — developer.apple.com (Program License Agreement banner)
   and App Store Connect → Business → Agreements. A pending agreement silently breaks
   distribution signing.
2. **Register the bundle id** `com.shaver.flowtear` (Certificates, Identifiers &
   Profiles → Identifiers → +).
3. **Create the app record** in App Store Connect → Apps → + with that bundle id.
4. **Create an App Store Connect API key** (Users and Access → Integrations →
   App Store Connect API → Team Keys → +):
   - **Access = App Manager or Admin** (prefer **Admin** on an org team — creating the
     first cloud-managed *distribution* certificate can require it). A **Developer**-role
     key gets through the archive and then fails at export with
     `Cloud signing permission error`.
   - **Download the `.p8` immediately** (Apple lets you download it once). Save
     `AuthKey_XXXXXXXXXX.p8`.
   - Note the **Key ID** (the row) and the **Issuer ID** (top of the page).
5. **Note your Team ID** (10 chars, developer.apple.com header).
6. **Invite an internal tester** (TestFlight → Internal Testing) so the build reaches a
   device after processing.

---

## 2. GitHub repo secrets (required)

Repo → Settings → Secrets and variables → Actions → New repository secret. All four are
required:

| Secret | Value |
|---|---|
| `APPLE_TEAM_ID` | Your 10-char Apple Team ID (e.g. `PJVY2JTX7W`). |
| `ASC_KEY_ID` | The API key's **Key ID**. |
| `ASC_ISSUER_ID` | The **Issuer ID** (shared by all team keys). |
| `ASC_KEY_P8_BASE64` | The `AuthKey_*.p8` contents, **base64-encoded** (see below). |
| `MATCH_PASSWORD` | A passphrase **you choose** — it encrypts the certs in the match repo. Keep it safe; you need the same value to bootstrap and to build. |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 of `githubuser:PAT` so CI can read the `flowtear-certs` repo (see §1.5). |

### Generating `ASC_KEY_P8_BASE64` on Windows

Base64 (rather than pasting the raw PEM) avoids Windows CRLF line endings corrupting the
key. The workflow decodes it back to a raw `.p8` before use. In PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\Downloads\AuthKey_XXXXXXXXXX.p8")) | Set-Clipboard
```

That copies a single base64 line to your clipboard — paste it as the secret value.
(macOS/Linux equivalent: `base64 -i AuthKey_XXXXXXXXXX.p8` / `base64 -w0 AuthKey_*.p8`.)

If you rotate the key, update **both** `ASC_KEY_ID` and `ASC_KEY_P8_BASE64`.

> Note: some pipelines store the `.p8` raw. Raw only works if it is a clean PEM with
> `-----BEGIN PRIVATE KEY-----` intact and no base64 wrapping — a base64 blob echoed raw
> gives `invalidPEMDocument`. This workflow expects the **base64** form and decodes it.

---

## 2.5 One-time: bootstrap match signing

Do this once. After it, every release just works and never touches certificates again.

1. **Create the private storage repo** (empty is fine — match fills it):
   ```powershell
   gh repo create flowtear-certs --private
   ```
   *(If you name it differently, update `git_url` in `fastlane/Matchfile`.)*

2. **Free a distribution-cert slot.** The earlier cloud-signed build left a throwaway
   Apple Distribution certificate in your account whose private key was discarded — it's
   dead weight against the cap. Revoke it at
   https://developer.apple.com/account/resources/certificates/list so match can create the
   one permanent cert it will keep. (Don't revoke a cert Bloom actively uses.)

3. **Add the two match secrets** (PowerShell, from the `flowtear` folder):
   ```powershell
   gh secret set MATCH_PASSWORD --body "<choose-a-strong-passphrase>"

   # PAT with 'repo' scope so CI can read flowtear-certs; base64 "user:PAT":
   $pair = "shaver3josiah:<your-PAT>"
   [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair)) `
     | gh secret set MATCH_GIT_BASIC_AUTHORIZATION
   ```
   Create the PAT at https://github.com/settings/tokens (classic, `repo` scope).

4. **Run the bootstrap workflow once** — it creates + stores the cert & profile:
   ```powershell
   gh workflow run bootstrap-signing.yml
   ```
   Watch it green in the Actions tab. When done, `flowtear-certs` holds the encrypted
   certificate + profile. You never do this step again (until certs expire in ~1 year,
   when you re-run it).

From then on, every `testflight` run fetches these read-only — no cert creation, no cap.

---

## 3. Fonts (drop in before your first real build)

`project.yml` already registers these under `UIAppFonts` (3 OFL families, 4 files). Drop
the `.ttf` files into `App/Resources/Fonts/` and commit them:

```
App/Resources/Fonts/Quicksand.ttf
App/Resources/Fonts/PlayfairDisplay.ttf
App/Resources/Fonts/PlayfairDisplay-Italic.ttf
App/Resources/Fonts/GreatVibes-Regular.ttf
```

Sources (SIL Open Font License): Quicksand, Playfair Display, and Great Vibes on Google
Fonts. If a file is missing the app still **builds and ships** — `Font.custom` falls back
to the system font (see `Theme.swift`) — the type just won't look branded.

---

## 4. First run

```powershell
git add -A
git commit -m "Ship it"
git push
git tag v0.1.0
git push origin v0.1.0        # this tag triggers the release
```

Watch the run under the repo's **Actions** tab. You can also trigger it manually from
there (Run workflow → `testflight`) via `workflow_dispatch`.

Because secrets are read at run time, if a step goes red because of a bad secret or a
pending agreement, fix it and just **Re-run** the same tag — no new commit needed.

Tags cannot be reused: the next release is `v0.1.1`, `v0.2.0`, etc.

**Done** = a green run whose final step is a successful `fastlane pilot` upload, and the
build appears in App Store Connect → TestFlight (processing takes a few minutes to ~an
hour), reaching your invited internal tester.

---

## Notes / gotchas baked in

- **Newest Xcode is selected** on the runner — Apple enforces a minimum build SDK.
- **API key stored base64, decoded in-workflow** — robust against Windows CRLF.
- **`ExportOptions.plist` is excluded from the app sources** (`project.yml`) so it isn't
  copied into the bundle; **`PrivacyInfo.xcprivacy` is included** so it ships in the
  bundle root.
- **App icon:** the App Store icon must be a flat **1024×1024 RGB PNG with no alpha**. If
  an upload reports "Missing required icon" / "Missing CFBundleIconName", the asset
  catalog at `App/Assets.xcassets/AppIcon.appiconset/` is the place to look.
- A failing run's log is best handed to the `ios-ci-ship-doctor` skill — it maps each
  cryptic Apple error to root cause and fix.
