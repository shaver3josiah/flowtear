import React from "react";

const PHASE = {
  menstrual: { label: "Menstrual", soft: "var(--phase-menstrual-soft)", fg: "var(--phase-menstrual)" },
  follicular: { label: "Follicular", soft: "var(--phase-follicular-soft)", fg: "#C4568A" },
  fertile: { label: "Fertile window", soft: "var(--phase-fertile-soft)", fg: "#B67A1E" },
  ovulation: { label: "Ovulation", soft: "var(--phase-ovulation-soft)", fg: "#B0700F" },
  luteal: { label: "Luteal", soft: "var(--phase-luteal-soft)", fg: "#9B569A" },
};

/**
 * PhaseBadge — a prominent current-phase indicator: a phase-tinted pill with a
 * color dot, the phase name, and an optional subtitle (e.g. "Day 3").
 */
export function PhaseBadge({ phase = "follicular", subtitle, className = "", style, ...rest }) {
  const p = PHASE[phase] || PHASE.follicular;
  return (
    <span
      className={className}
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: "8px",
        padding: "8px 14px",
        borderRadius: "var(--radius-pill)",
        background: p.soft,
        color: p.fg,
        fontFamily: "var(--font-body)",
        fontSize: "var(--text-sm)",
        ...style,
      }}
      {...rest}
    >
      <span style={{ width: 8, height: 8, borderRadius: "50%", background: "currentColor", flex: "none" }} />
      <span style={{ fontWeight: "var(--weight-semibold)" }}>{p.label}</span>
      {subtitle && <span style={{ opacity: 0.8, fontWeight: "var(--weight-medium)" }}>· {subtitle}</span>}
    </span>
  );
}
