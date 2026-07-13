import React from "react";

function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

injectOnce(
  "ft-card-css",
  `.ft-card{border-radius:var(--radius);padding:var(--gap-card);background:var(--surface);box-shadow:var(--shadow-card);transition:transform var(--dur-base) var(--ease-out),box-shadow var(--dur-base) var(--ease-out)}
.ft-card--soft{background:var(--surface-soft);box-shadow:none}
.ft-card--accent{background:var(--surface-2);box-shadow:none}
.ft-card--outline{background:var(--surface);box-shadow:none;border:1px solid var(--line)}
.ft-card--interactive{cursor:pointer}
.ft-card--interactive:hover{transform:translateY(-2px);box-shadow:var(--shadow-float)}
.ft-card--interactive:active{transform:translateY(0)}`
);

/**
 * Card — the fundamental surface. White with a soft themed drop shadow and the
 * canonical 22px corner (from the Bloom Card). Soft/accent/outline variants for
 * quieter panels.
 */
export function Card({ variant = "plain", interactive = false, as = "div", padding, className = "", style, children, ...rest }) {
  const Tag = as;
  const cls = ["ft-card", variant !== "plain" ? `ft-card--${variant}` : "", interactive ? "ft-card--interactive" : "", className]
    .filter(Boolean)
    .join(" ");
  return (
    <Tag className={cls} style={padding != null ? { padding, ...style } : style} {...rest}>
      {children}
    </Tag>
  );
}
