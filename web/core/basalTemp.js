// Basal temperature in the unit her region actually uses — the web mirror of
// App/Core/BasalTemp.swift. Storage stays Celsius everywhere (DayLog.temperatureC
// is the contract); only the display, the slider bounds and the spoken value
// change. Every screen that shows a waking temperature routes through here, so
// there is one place to be right.
//
// ponytail: read from the locale, like the native side. No setting to find and
// nothing to migrate — add a manual override only if someone actually asks.

// The US reads body temperature in Fahrenheit; everyone else, the UK included,
// reads Celsius. `Intl.Locale.measurementSystem` is the authority where the
// engine exposes it (most do not yet), and this list is the fallback.
//
// Deliberately US-only, to match Swift's `Locale.measurementSystem != .us`
// exactly: Foundation calls Belize and the Bahamas metric, so adding them here
// would make the two platforms disagree about the same phone's region. Parity
// is the harder rule; those users get Celsius on both.
const F_REGIONS = ["US"];

/// Celsius or not, for one locale tag. Exported so it is testable — reading
/// `navigator` straight from module scope made this unverifiable, and the
/// catch-all then hid the failure behind a plausible-looking Fahrenheit.
export function detect(tag) {
  try {
    const loc = new Intl.Locale(tag);
    const max = typeof loc.maximize === "function" ? loc.maximize() : loc;
    const sys = max.measurementSystem ?? loc.measurementSystem;
    if (sys) return sys !== "ussystem";
    return !F_REGIONS.includes(max.region || "");
  } catch {
    return null; // not a locale we can read
  }
}

function browserTag() {
  try {
    return globalThis.navigator?.language || null;
  } catch {
    return null;
  }
}

// Unknown locale keeps the unit the app has always shown, rather than silently
// reinterpreting her saved readings.
export const usesCelsius = detect(browserTag()) ?? false;

export const unit = usesCelsius ? "°C" : "°F";

// Plausible waking-temperature span, in display units. The two ranges are the
// same span: 96–100 °F is 35.6–37.8 °C.
export const min = usesCelsius ? 35.6 : 96.0;
export const max = usesCelsius ? 37.8 : 100.0;

// One step of a drugstore basal thermometer.
export const step = 0.05;

// A typical waking reading, for seeding a slider she hasn't moved yet.
export const typicalDisplay = usesCelsius ? 36.5 : 97.8;

export const display = (c) =>
  c == null ? null : (usesCelsius ? c : (c * 9) / 5 + 32);

export const celsius = (v) =>
  v == null ? null : (usesCelsius ? v : ((v - 32) * 5) / 9);

export const typicalCelsius = celsius(typicalDisplay);

/// "36.50" — the number alone, to pair with `unit`.
export const text = (c, digits = 2) => {
  const d = display(c);
  return d == null ? null : d.toFixed(digits);
};

/// "36.50 °C" — number and unit, for one-line readouts and reports.
export const labelled = (c, digits = 2) => {
  const t = text(c, digits);
  return t == null ? null : `${t} ${unit}`;
};

// Self-check: node web/core/basalTemp.js
if (import.meta.main) {
  const assert = (await import("node:assert")).default;

  // The unit follows the region, not the language.
  for (const tag of ["en-GB", "de-DE", "ja-JP", "fr-CA", "en-AU", "es-MX"]) {
    assert.equal(detect(tag), true, `${tag} reads Celsius`);
  }
  for (const tag of ["en-US", "es-US"]) {
    assert.equal(detect(tag), false, `${tag} reads Fahrenheit`);
  }
  // Matches Swift's measurementSystem check, which calls these metric.
  assert.equal(detect("en-BZ"), true, "Belize follows Foundation, for parity");
  assert.equal(detect("not a locale"), null, "unreadable tag reports nothing");
  assert.equal(detect(null), null, "missing tag reports nothing");

  // Whatever she slides to is what comes back out, in either unit.
  for (let c = 35; c <= 38; c += 0.1) {
    assert.ok(Math.abs(celsius(display(c)) - c) < 1e-9, "round trip");
  }

  // The slider's bounds are the same physical span either way, and the seed
  // value sits inside them — otherwise the first drag jumps.
  assert.ok(Math.abs(celsius(min) - 35.6) < 0.1, "low bound");
  assert.ok(Math.abs(celsius(max) - 37.8) < 0.1, "high bound");
  assert.ok(typicalDisplay >= min && typicalDisplay <= max, "seed inside range");
  assert.equal(display(typicalCelsius).toFixed(2), typicalDisplay.toFixed(2), "seed round trip");

  assert.equal(labelled(36.85), `${text(36.85)} ${unit}`, "labelled pairs number and unit");
  assert.equal(text(null), null, "no reading, no text");
  console.log("basalTemp.js self-check ok");
}
