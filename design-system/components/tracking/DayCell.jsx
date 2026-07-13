import React from "react";

const FLOW_COLOR = {
  spotting: "var(--flow-spotting)",
  light: "var(--flow-light)",
  medium: "var(--flow-medium)",
  heavy: "var(--flow-heavy)",
  none: "var(--flow-none)",
};

/**
 * DayCell — one calendar day. Composable states: period (logged bleed),
 * predicted (forecast period), fertile, ovulation; plus today, selected and
 * muted (outside month). An optional flow dot shows logged intensity.
 */
export function DayCell({ day, state = null, flow = null, today = false, selected = false, muted = false, size = 40, onClick, className = "", style, ...rest }) {
  let bg = "transparent";
  let color = "var(--text)";
  let border = "1.5px solid transparent";
  let boxShadow = "none";

  if (state === "fertile") { bg = "var(--phase-fertile-soft)"; color = "#8a5a12"; }
  if (state === "ovulation") { bg = "var(--phase-fertile-soft)"; border = "2px solid var(--phase-ovulation)"; color = "#8a5a12"; }
  if (state === "period") { bg = "var(--phase-menstrual-soft)"; color = "var(--phase-menstrual)"; }
  if (state === "predicted") { border = "1.5px dashed var(--phase-menstrual)"; color = "var(--phase-menstrual)"; }
  if (muted) color = "color-mix(in srgb, var(--muted) 42%, transparent)";
  if (today) boxShadow = "0 0 0 2px var(--surface), 0 0 0 4px var(--primary-strong)";
  if (selected) { bg = "var(--primary-strong)"; color = "#fff"; border = "1.5px solid transparent"; }

  const dot = flow && !selected ? FLOW_COLOR[flow] : null;
  const Tag = onClick ? "button" : "div";
  return (
    <Tag
      className={className}
      onClick={onClick}
      {...(onClick ? { type: "button" } : {})}
      style={{
        position: "relative",
        width: size,
        height: size,
        borderRadius: "50%",
        border,
        background: bg,
        color,
        boxShadow,
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: "var(--font-body)",
        fontWeight: today || selected ? "var(--weight-bold)" : "var(--weight-medium)",
        fontSize: "var(--text-sm)",
        cursor: onClick ? "pointer" : "default",
        padding: 0,
        transition: "background var(--dur-base) var(--ease-out), transform var(--dur-fast) var(--ease-out)",
        ...style,
      }}
      {...rest}
    >
      {day}
      {dot && (
        <span style={{ position: "absolute", bottom: size * 0.14, width: 5, height: 5, borderRadius: "50%", background: dot }} />
      )}
    </Tag>
  );
}
