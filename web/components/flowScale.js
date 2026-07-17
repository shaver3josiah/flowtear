// FlowScale — the period flow selector, spotting → super heavy. Port of
// App/Components/FlowScale.swift (five droplets that deepen and grow).
//
// WHY THIS EXISTS instead of ctx.ui.FlowScale: the vendored ds-bundle is
// uneditable and its FLOW_LEVELS only knows four levels, so it can no longer
// represent core/models.js FLOW (which gained `superHeavy`). Bolting a fifth
// cell onto the vendored component would split one selector across two flex
// groups, two aria groups and two onChange paths; rendering all five here is
// both faithful and the smaller diff.
//
// ponytail: this REUSES the bundle's already-injected `.ft-flow*` CSS rather
// than restyling from scratch — hover / :active / [aria-pressed] / :focus-visible
// can't be inline styles, so the classes are the only way to keep the vendored
// look exactly. Ceiling: if a future bundle drops those class names, inject a
// local <style> here the way components/glitterHint.js does.
// Motion is already reduced-motion-gated: the classes animate on --dur-base /
// --dur-fast, which tokens.css collapses to .001s under the media query.

import { FLOW, label } from "../core/models.js";

const React = window.React;
const html = window.htm.bind(React.createElement);

// The `--flow-*` ramp, extended by one. `--flow-super-heavy` is a real token
// mirroring Theme.swift's flowSuperHeavy: #96164A on light presets, and a hot
// crimson #FF4D6D on the dark ones — because the deepest flow has to be the
// MOST visible on dark, not the least (Theme.swift says so in its own words).
export const FLOW_COLOR = {
  spotting: "var(--flow-spotting)",
  light: "var(--flow-light)",
  medium: "var(--flow-medium)",
  heavy: "var(--flow-heavy)",
  superHeavy: "var(--flow-super-heavy)",
};

// Droplet size per level (FlowScale.swift: 20 / 24 / 28 / 32 / 36).
const DROP = { spotting: 20, light: 24, medium: 28, heavy: 32, superHeavy: 36 };

// The bundle's droplet path, so the vendored and local scales draw identically.
const Droplet = ({ color, size }) => html`
  <svg class="ft-flowcell__drop" width=${size} height=${size} viewBox="0 0 24 24" aria-hidden="true">
    <path d="M12 2.4c0 0-6.6 7.5-6.6 12.3a6.6 6.6 0 0 0 13.2 0C18.6 9.9 12 2.4 12 2.4Z" fill=${color} />
  </svg>`;

/// Single-select, tap-to-clear. Same props as ctx.ui.FlowScale — `value` /
/// `onChange(level | null)` / `block` — so it's a drop-in replacement.
export function FlowScale({ value = null, onChange, block = true, className = "", ...rest }) {
  const cls = ["ft-flow", block ? "ft-flow--block" : "", className].filter(Boolean).join(" ");
  return html`
    <div class=${cls} role="group" aria-label="Flow intensity" ...${rest}>
      ${FLOW.map((k) => html`
        <button key=${k} type="button" class="ft-flowcell" aria-pressed=${value === k}
          onClick=${() => onChange && onChange(value === k ? null : k)}>
          <${Droplet} color=${FLOW_COLOR[k]} size=${DROP[k]} />
          <span class="ft-flowcell__label">${label(k)}</span>
        </button>`)}
    </div>`;
}

export default FlowScale;
