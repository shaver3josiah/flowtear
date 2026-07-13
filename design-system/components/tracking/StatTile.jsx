import React from "react";

/**
 * StatTile — a compact stat panel: a big Playfair value with a muted label and
 * an optional icon. Grid these for the Insights summary (avg cycle, avg period,
 * cycles tracked, …).
 */
export function StatTile({ value, unit, label, icon, tone = "soft", className = "", style, ...rest }) {
  const bg = tone === "accent" ? "var(--surface-2)" : tone === "card" ? "var(--surface)" : "var(--surface-soft)";
  return (
    <div
      className={className}
      style={{
        background: bg,
        borderRadius: "var(--radius-md)",
        padding: "16px",
        display: "flex",
        flexDirection: "column",
        gap: "3px",
        boxShadow: tone === "card" ? "var(--shadow-card)" : "none",
        ...style,
      }}
      {...rest}
    >
      {icon && <span style={{ color: "var(--primary-strong)", display: "inline-flex", marginBottom: 2 }}>{icon}</span>}
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 600, fontSize: "var(--text-2xl)", color: "var(--deep)", lineHeight: 1 }}>
        {value}
        {unit && <span style={{ fontSize: "0.5em", color: "var(--muted)", fontWeight: 500, marginLeft: 3 }}>{unit}</span>}
      </span>
      <span style={{ fontFamily: "var(--font-body)", fontSize: "var(--text-xs)", color: "var(--muted)", fontWeight: 500 }}>{label}</span>
    </div>
  );
}
