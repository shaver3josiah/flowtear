import React from "react";

function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

injectOnce(
  "ft-btn-css",
  `.ft-btn{display:inline-flex;align-items:center;justify-content:center;gap:.5em;font-family:var(--font-body);font-weight:var(--weight-semibold);border:none;border-radius:var(--radius-pill);cursor:pointer;white-space:nowrap;user-select:none;line-height:1;text-decoration:none;transition:transform var(--dur-fast) var(--ease-out),box-shadow var(--dur-base) var(--ease-out),background var(--dur-base) var(--ease-out),filter var(--dur-base) var(--ease-out)}
.ft-btn--sm{height:38px;padding:0 16px;font-size:var(--text-sm)}
.ft-btn--md{height:46px;padding:0 22px;font-size:var(--text-base)}
.ft-btn--lg{height:54px;padding:0 30px;font-size:var(--text-md)}
.ft-btn--block{width:100%}
.ft-btn--primary{background:var(--primary-strong);color:#fff;box-shadow:0 8px 20px -10px var(--shadow)}
.ft-btn--primary:hover{filter:brightness(1.05);box-shadow:0 12px 26px -10px var(--shadow)}
.ft-btn--deep{background:var(--deep);color:#fff;box-shadow:0 8px 20px -10px var(--shadow)}
.ft-btn--deep:hover{filter:brightness(1.08)}
.ft-btn--soft{background:var(--surface-soft);color:var(--deep)}
.ft-btn--soft:hover{background:color-mix(in srgb,var(--surface-soft) 76%,var(--primary) 24%)}
.ft-btn--ghost{background:transparent;color:var(--primary-strong)}
.ft-btn--ghost:hover{background:var(--surface-soft)}
.ft-btn:active{transform:scale(.96)}
.ft-btn:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-btn:disabled,.ft-btn[aria-disabled="true"]{opacity:.45;pointer-events:none;box-shadow:none}
.ft-btn__ico{display:inline-flex;flex:none}`
);

/**
 * Button — the primary action pill. Rounded to a full capsule, springy on
 * press, soft themed shadow. Variants cover the emphasis ladder.
 */
export function Button({ variant = "primary", size = "md", block = false, iconLeft, iconRight, className = "", children, ...rest }) {
  const cls = ["ft-btn", `ft-btn--${variant}`, `ft-btn--${size}`, block ? "ft-btn--block" : "", className].filter(Boolean).join(" ");
  return (
    <button className={cls} {...rest}>
      {iconLeft && <span className="ft-btn__ico">{iconLeft}</span>}
      {children}
      {iconRight && <span className="ft-btn__ico">{iconRight}</span>}
    </button>
  );
}
