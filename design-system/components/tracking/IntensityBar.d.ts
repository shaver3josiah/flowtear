import React from "react";

export interface IntensityBarProps extends React.HTMLAttributes<HTMLDivElement> {
  /** Row label, e.g. "Medium" or "Cramps". */
  label: React.ReactNode;
  /** Fill fraction, 0–1. */
  value?: number;
  /** Fill color (default primary) — pass a `--flow-*` / `--phase-*` token. */
  color?: string;
  /** Right-aligned meta, e.g. "6 days" or "42%". */
  meta?: React.ReactNode;
}

/**
 * IntensityBar — a labeled horizontal bar for breakdown charts: flow-by-day,
 * pain levels, symptom frequency. Stack several in a Card with a title to make
 * an insights chart. Colors come from the `--flow-*` / `--phase-*` ramps.
 */
export declare function IntensityBar(props: IntensityBarProps): JSX.Element;
