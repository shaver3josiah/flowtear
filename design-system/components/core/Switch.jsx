import React from "react";

function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

injectOnce(
  "ft-switch-css",
  `.ft-switch{position:relative;display:inline-flex;align-items:center;width:52px;height:30px;border-radius:var(--radius-pill);background:var(--surface-soft);border:none;cursor:pointer;padding:0;flex:none;transition:background var(--dur-base) var(--ease-out)}
.ft-switch[aria-checked="true"]{background:var(--primary-strong)}
.ft-switch__knob{position:absolute;top:3px;left:3px;width:24px;height:24px;border-radius:50%;background:#fff;box-shadow:0 2px 6px rgba(66,21,39,.28);transition:transform var(--dur-base) var(--spring)}
.ft-switch[aria-checked="true"] .ft-switch__knob{transform:translateX(22px)}
.ft-switch:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-switch:disabled{opacity:.4;pointer-events:none}`
);

/**
 * Switch — the settings/reminder toggle. Track fills strong-pink when on; the
 * knob springs across. Controlled via `checked`/`onChange`.
 */
export function Switch({ checked = false, onChange, label, className = "", disabled, ...rest }) {
  const cls = ["ft-switch", className].filter(Boolean).join(" ");
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      className={cls}
      onClick={() => onChange && onChange(!checked)}
      {...rest}
    >
      <span className="ft-switch__knob" />
    </button>
  );
}
