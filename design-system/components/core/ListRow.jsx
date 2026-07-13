import React from "react";

function injectOnce(id, css) {
  if (typeof document === "undefined" || document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

injectOnce(
  "ft-listrow-css",
  `.ft-listrow{display:flex;align-items:center;gap:14px;width:100%;padding:12px 4px;background:transparent;border:none;text-align:left;font-family:var(--font-body);color:var(--text)}
.ft-listrow--interactive{cursor:pointer;border-radius:var(--radius-md);padding:12px;transition:background var(--dur-base) var(--ease-out)}
.ft-listrow--interactive:hover{background:var(--surface-2)}
.ft-listrow--interactive:active{background:var(--surface-soft)}
.ft-listrow__lead{width:40px;height:40px;border-radius:var(--radius-sm);background:var(--surface-soft);display:grid;place-items:center;color:var(--primary-strong);flex:none}
.ft-listrow__body{flex:1;min-width:0;display:flex;flex-direction:column;gap:2px}
.ft-listrow__title{font-size:var(--text-base);font-weight:var(--weight-semibold);color:var(--text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.ft-listrow__sub{font-size:var(--text-xs);color:var(--muted);overflow:hidden;text-overflow:ellipsis}
.ft-listrow__trail{flex:none;display:inline-flex;align-items:center;gap:8px;color:var(--muted);font-size:var(--text-sm);font-weight:var(--weight-medium)}`
);

/**
 * ListRow — a settings / reminders row: soft rounded leading icon, title +
 * subtitle, and a trailing slot (Switch, chevron, value). Renders as a button
 * when `onClick` is given.
 */
export function ListRow({ icon, title, subtitle, trailing, onClick, className = "", ...rest }) {
  const interactive = !!onClick;
  const Tag = interactive ? "button" : "div";
  const cls = ["ft-listrow", interactive ? "ft-listrow--interactive" : "", className].filter(Boolean).join(" ");
  return (
    <Tag className={cls} onClick={onClick} {...(interactive ? { type: "button" } : {})} {...rest}>
      {icon && <span className="ft-listrow__lead">{icon}</span>}
      <span className="ft-listrow__body">
        <span className="ft-listrow__title">{title}</span>
        {subtitle && <span className="ft-listrow__sub">{subtitle}</span>}
      </span>
      {trailing && <span className="ft-listrow__trail">{trailing}</span>}
    </Tag>
  );
}
