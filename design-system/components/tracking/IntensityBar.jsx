import React from "react";

function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

injectOnce(
  "ft-ibar-css",
  `.ft-ibar{display:flex;flex-direction:column;gap:6px;font-family:var(--font-body)}
.ft-ibar__head{display:flex;justify-content:space-between;align-items:baseline;gap:8px}
.ft-ibar__label{font-size:var(--text-sm);font-weight:var(--weight-semibold);color:var(--text)}
.ft-ibar__meta{font-size:var(--text-xs);color:var(--muted);flex:none}
.ft-ibar__track{height:9px;border-radius:var(--radius-pill);background:var(--surface-soft);overflow:hidden}
.ft-ibar__fill{height:100%;border-radius:var(--radius-pill);transition:width var(--dur-slow) var(--ease-signature)}`
);

/**
 * IntensityBar — a labeled horizontal bar for breakdown charts (flow-by-day,
 * pain, symptom frequency). Give it a 0–1 `value` and a `color`.
 */
export function IntensityBar({ label, value = 0, color = "var(--primary)", meta, className = "", ...rest }) {
  const pct = Math.max(0, Math.min(1, value)) * 100;
  return (
    <div className={["ft-ibar", className].filter(Boolean).join(" ")} {...rest}>
      <div className="ft-ibar__head">
        <span className="ft-ibar__label">{label}</span>
        {meta != null && <span className="ft-ibar__meta">{meta}</span>}
      </div>
      <div className="ft-ibar__track">
        <div className="ft-ibar__fill" style={{ width: pct + "%", background: color }} />
      </div>
    </div>
  );
}
