// GlitterHint — port of App/Components/GlitterHint.swift. A tiny twinkle of gold
// over a control she hasn't tried yet (the theme pencil, the tips bulb…). The
// first tap retires the hint for good, per key. Reduce Motion shows one still
// sparkle instead of the twinkling.
//
// Swift uses a ViewModifier (`.glitterHint("tips")`); the web equivalent is a
// wrapper: html`<${GlitterHint} hintKey="tips"><${IconButton} …/></${GlitterHint}>`.
// The localStorage key matches the Swift UserDefaults key EXACTLY
// ("flowtear.glitter." + key), so the two builds retire the same hints.

const React = window.React;
const { useState } = React;
const html = window.htm.bind(React.createElement);

const storeKey = (k) => "flowtear.glitter." + k;
const reduceMotion = () =>
  typeof window.matchMedia === "function" &&
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

// One <style> for the twinkle keyframes — this component owns the effect, and
// there is no build step to fold it into the shared stylesheet.
const STYLE_ID = "ft-glitter-css";
if (typeof document !== "undefined" && !document.getElementById(STYLE_ID)) {
  const el = document.createElement("style");
  el.id = STYLE_ID;
  el.textContent =
    "@keyframes ft-twinkle { from { opacity: .15; transform: scale(.6); } to { opacity: 1; transform: none; } }";
  document.head.appendChild(el);
}

// A four-point sparkle, standing in for SF Symbols' "sparkle".
const Sparkle = ({ size, delay, color, dx, dy, still }) => html`
  <svg width=${size} height=${size} viewBox="0 0 10 10" aria-hidden="true"
    style=${{
      position: "absolute", top: 0, right: 0,
      transform: `translate(${dx}px, ${dy}px)`,
      animation: still ? "none" : `ft-twinkle .9s ease-in-out ${delay}s infinite alternate`,
      opacity: still ? 1 : 0.15,
    }}>
    <path d="M5 0C5.6 3.2 6.8 4.4 10 5C6.8 5.6 5.6 6.8 5 10C4.4 6.8 3.2 5.6 0 5C3.2 4.4 4.4 3.2 5 0Z"
      fill=${color} />
  </svg>`;

export function GlitterHint({ hintKey, children }) {
  const [pressed, setPressed] = useState(
    () => typeof localStorage !== "undefined" && localStorage.getItem(storeKey(hintKey)) === "true"
  );

  const retire = () => {
    if (pressed) return;
    localStorage.setItem(storeKey(hintKey), "true");
    setPressed(true);
  };

  const still = reduceMotion();

  return html`
    <span onClickCapture=${retire} style=${{ position: "relative", display: "inline-flex" }}>
      ${children}
      ${!pressed &&
      html`<span aria-hidden="true"
        style=${{ position: "absolute", top: 0, right: 0, pointerEvents: "none" }}>
        <${Sparkle} size=${9} delay=${0} color="var(--flower-center)" dx=${5} dy=${-5} still=${still} />
        ${!still && html`
          <${Sparkle} size=${6} delay=${0.35} color="var(--primary)" dx=${-7} dy=${-9} />
          <${Sparkle} size=${7} delay=${0.7} color="var(--flower-center)" dx=${9} dy=${7} />`}
      </span>`}
    </span>`;
}

export default GlitterHint;
