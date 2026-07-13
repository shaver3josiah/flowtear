# Fonts (drop-in)

The app requests three OFL families (see `App/Design/Theme.swift` → `ffBody`/`ffDisplay`/`ffNumber`/`ffScript`)
and lists them in `project.yml` under `UIAppFonts`. Until the `.ttf` files are here, `Font.custom` silently
falls back to the system font — the app **builds and runs**, it just loses the brand type + numerals.

Drop these files into this folder (filenames must match `project.yml`):

- `Quicksand.ttf` — https://fonts.google.com/specimen/Quicksand
- `PlayfairDisplay.ttf` and `PlayfairDisplay-Italic.ttf` — https://fonts.google.com/specimen/Playfair+Display
- `GreatVibes-Regular.ttf` — https://fonts.google.com/specimen/Great+Vibes

All are OFL-licensed (free to bundle). Commit them so CI picks them up.
