import React from "react";

export interface StatTileProps extends React.HTMLAttributes<HTMLDivElement> {
  /** The headline value (rendered in Playfair). */
  value: React.ReactNode;
  /** Small trailing unit, e.g. "days". */
  unit?: string;
  /** Muted caption under the value. */
  label: React.ReactNode;
  /** Optional icon node above the value. */
  icon?: React.ReactNode;
  /** Panel treatment. Default "soft". */
  tone?: "soft" | "accent" | "card";
}

/**
 * StatTile — a compact stat panel (big Playfair value + muted label). Grid
 * these for the Insights summary: average cycle length, average period,
 * cycles tracked, current streak.
 *
 * @startingPoint section="Tracking" subtitle="Insight stat tiles" viewport="360x160"
 */
export declare function StatTile(props: StatTileProps): JSX.Element;
