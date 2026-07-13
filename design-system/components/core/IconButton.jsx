import React from "react";

function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

injectOnce(
  "ft-iconbtn-css",
  `.ft-iconbtn{display:inline-flex;align-items:center;justify-content:center;border:none;border-radius:var(--radius-pill);cursor:pointer;flex:none;color:var(--deep);transition:transform var(--dur-fast) var(--ease-out),background var(--dur-base) var(--ease-out),filter var(--dur-base) var(--ease-out)}
.ft-iconbtn--sm{width:36px;height:36px}
.ft-iconbtn--md{width:44px;height:44px}
.ft-iconbtn--lg{width:52px;height:52px}
.ft-iconbtn--soft{background:var(--surface-soft);color:var(--deep)}
.ft-iconbtn--soft:hover{background:color-mix(in srgb,var(--surface-soft) 76%,var(--primary) 24%)}
.ft-iconbtn--ghost{background:transparent;color:var(--muted)}
.ft-iconbtn--ghost:hover{background:var(--surface-soft);color:var(--deep)}
.ft-iconbtn--primary{background:var(--primary-strong);color:#fff;box-shadow:0 8px 18px -10px var(--shadow)}
.ft-iconbtn--primary:hover{filter:brightness(1.06)}
.ft-iconbtn:active{transform:scale(.92)}
.ft-iconbtn:focus-visible{outline:var(--ring-width) solid var(--focus-ring);outline-offset:2px}
.ft-iconbtn:disabled{opacity:.4;pointer-events:none}`
);

/**
 * IconButton — a round, icon-only tap target (min 44px). For toolbar actions,
 * calendar nav arrows, close buttons, and the like.
 */
export function IconButton({ variant = "soft", size = "md", label, className = "", children, ...rest }) {
  const cls = ["ft-iconbtn", `ft-iconbtn--${variant}`, `ft-iconbtn--${size}`, className].filter(Boolean).join(" ");
  return (
    <button className={cls} aria-label={label} {...rest}>
      {children}
    </button>
  );
}
