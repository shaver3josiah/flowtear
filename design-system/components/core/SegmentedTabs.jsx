import React from "react";

function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

injectOnce(
  "ft-segtabs-css",
  `.ft-segtabs{display:inline-flex;gap:4px;padding:4px;background:var(--surface-soft);border-radius:var(--radius-pill)}
.ft-segtabs--block{display:flex;width:100%}
.ft-seg{flex:1;display:inline-flex;align-items:center;justify-content:center;gap:.4em;border:none;background:transparent;cursor:pointer;font-family:var(--font-body);font-weight:var(--weight-semibold);font-size:var(--text-sm);color:var(--muted);height:36px;padding:0 18px;border-radius:var(--radius-pill);white-space:nowrap;transition:color var(--dur-base) var(--ease-out),background var(--dur-base) var(--ease-out),box-shadow var(--dur-base) var(--ease-out)}
.ft-seg:hover{color:var(--deep)}
.ft-seg[aria-selected="true"]{background:var(--primary-strong);color:#fff;box-shadow:0 4px 12px -6px var(--shadow)}
.ft-seg:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-seg__ico{display:inline-flex;flex:none}`
);

/**
 * SegmentedTabs — the capsule tab switcher from the Bloom KTabBar. A soft
 * track with a strong-pink active pill. Controlled via `value`/`onChange`.
 */
export function SegmentedTabs({ options = [], value, onChange, block = false, className = "", ...rest }) {
  const cls = ["ft-segtabs", block ? "ft-segtabs--block" : "", className].filter(Boolean).join(" ");
  return (
    <div className={cls} role="tablist" {...rest}>
      {options.map((opt) => {
        const val = typeof opt === "string" ? opt : opt.value;
        const label = typeof opt === "string" ? opt : opt.label;
        const icon = typeof opt === "string" ? null : opt.icon;
        const selected = val === value;
        return (
          <button
            key={val}
            type="button"
            role="tab"
            aria-selected={selected}
            className="ft-seg"
            onClick={() => onChange && onChange(val)}
          >
            {icon && <span className="ft-seg__ico">{icon}</span>}
            {label}
          </button>
        );
      })}
    </div>
  );
}
