import React from "react";

function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

injectOnce(
  "ft-chip-css",
  `.ft-chip{display:inline-flex;align-items:center;gap:.4em;font-family:var(--font-body);font-weight:var(--weight-semibold);border-radius:var(--radius-pill);border:1.5px solid transparent;cursor:pointer;user-select:none;background:var(--surface-soft);color:var(--muted);transition:transform var(--dur-fast) var(--ease-out),background var(--dur-base) var(--ease-out),color var(--dur-base) var(--ease-out),border-color var(--dur-base) var(--ease-out)}
.ft-chip--sm{height:32px;padding:0 12px;font-size:var(--text-xs)}
.ft-chip--md{height:40px;padding:0 16px;font-size:var(--text-sm)}
.ft-chip:hover{color:var(--deep);border-color:var(--line)}
.ft-chip[aria-pressed="true"]{background:var(--primary-strong);color:#fff;border-color:transparent}
.ft-chip[aria-pressed="true"]:hover{color:#fff;filter:brightness(1.04)}
.ft-chip:active{transform:scale(.95)}
.ft-chip:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-chip:disabled{opacity:.4;pointer-events:none}
.ft-chip__ico{display:inline-flex;flex:none}`
);

/**
 * Chip — a selectable pill for multi-select vocabularies (symptoms, moods,
 * tags). Toggles to the strong-pink selected state. Controlled via `selected`.
 */
export function Chip({ selected = false, size = "md", icon, onClick, className = "", children, ...rest }) {
  const cls = ["ft-chip", `ft-chip--${size}`, className].filter(Boolean).join(" ");
  return (
    <button type="button" className={cls} aria-pressed={selected} onClick={onClick} {...rest}>
      {icon && <span className="ft-chip__ico">{icon}</span>}
      {children}
    </button>
  );
}
