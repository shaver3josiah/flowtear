import React from "react";

function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

injectOnce(
  "ft-badge-css",
  `.ft-badge{display:inline-flex;align-items:center;gap:.45em;font-family:var(--font-body);font-weight:var(--weight-semibold);font-size:var(--text-xs);height:24px;padding:0 10px;border-radius:var(--radius-pill);letter-spacing:var(--tracking-wide);white-space:nowrap;line-height:1}
.ft-badge__dot{width:7px;height:7px;border-radius:50%;background:currentColor;flex:none}
.ft-badge--neutral{background:var(--surface-soft);color:var(--muted)}
.ft-badge--menstrual{background:var(--phase-menstrual-soft);color:var(--phase-menstrual)}
.ft-badge--follicular{background:var(--phase-follicular-soft);color:#C4568A}
.ft-badge--fertile{background:var(--phase-fertile-soft);color:#B67A1E}
.ft-badge--ovulation{background:var(--phase-ovulation-soft);color:#B0700F}
.ft-badge--luteal{background:var(--phase-luteal-soft);color:#9B569A}
.ft-badge--good{background:color-mix(in srgb,var(--good) 14%,#fff);color:var(--good)}`
);

/**
 * Badge — a small soft-tinted status label with an optional leading dot.
 * Tones map to cycle phases plus neutral & good.
 */
export function Badge({ tone = "neutral", dot = false, className = "", children, ...rest }) {
  const cls = ["ft-badge", `ft-badge--${tone}`, className].filter(Boolean).join(" ");
  return (
    <span className={cls} {...rest}>
      {dot && <span className="ft-badge__dot" />}
      {children}
    </span>
  );
}
