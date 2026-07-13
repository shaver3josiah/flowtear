import React from "react";

function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

injectOnce(
  "ft-flow-css",
  `.ft-flow{display:flex;gap:8px}
.ft-flow--block{width:100%}
.ft-flowcell{flex:1;display:flex;flex-direction:column;align-items:center;gap:6px;padding:12px 6px;border-radius:var(--radius-md);border:1.5px solid transparent;background:transparent;cursor:pointer;transition:background var(--dur-base) var(--ease-out),border-color var(--dur-base) var(--ease-out),transform var(--dur-fast) var(--ease-out)}
.ft-flowcell:hover{background:var(--surface-2)}
.ft-flowcell:active{transform:scale(.95)}
.ft-flowcell[aria-pressed="true"]{background:var(--surface-soft);border-color:var(--line)}
.ft-flowcell:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-flowcell__label{font-family:var(--font-body);font-size:var(--text-xs);font-weight:var(--weight-semibold);color:var(--muted)}
.ft-flowcell[aria-pressed="true"] .ft-flowcell__label{color:var(--deep)}
.ft-flowcell__drop{opacity:.45;transition:opacity var(--dur-base) var(--ease-out)}
.ft-flowcell[aria-pressed="true"] .ft-flowcell__drop{opacity:1}`
);

export const FLOW_LEVELS = [
  { key: "spotting", label: "Spotting", color: "var(--flow-spotting)", drop: 20 },
  { key: "light", label: "Light", color: "var(--flow-light)", drop: 24 },
  { key: "medium", label: "Medium", color: "var(--flow-medium)", drop: 28 },
  { key: "heavy", label: "Heavy", color: "var(--flow-heavy)", drop: 32 },
];

function Droplet({ color, size }) {
  return (
    <svg className="ft-flowcell__drop" width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 2.4c0 0-6.6 7.5-6.6 12.3a6.6 6.6 0 0 0 13.2 0C18.6 9.9 12 2.4 12 2.4Z" fill={color} />
    </svg>
  );
}

/**
 * FlowScale — the period flow selector: four droplets that deepen and grow from
 * spotting to heavy. Single-select; controlled via `value`/`onChange`.
 */
export function FlowScale({ value = null, onChange, block = true, className = "", ...rest }) {
  const cls = ["ft-flow", block ? "ft-flow--block" : "", className].filter(Boolean).join(" ");
  return (
    <div className={cls} role="group" aria-label="Flow intensity" {...rest}>
      {FLOW_LEVELS.map((lvl) => (
        <button
          key={lvl.key}
          type="button"
          className="ft-flowcell"
          aria-pressed={value === lvl.key}
          onClick={() => onChange && onChange(value === lvl.key ? null : lvl.key)}
        >
          <Droplet color={lvl.color} size={lvl.drop} />
          <span className="ft-flowcell__label">{lvl.label}</span>
        </button>
      ))}
    </div>
  );
}
