import React from "react";

export type FlowLevel = "spotting" | "light" | "medium" | "heavy";

export interface FlowScaleProps extends React.HTMLAttributes<HTMLDivElement> {
  /** Selected level, or null. */
  value?: FlowLevel | null;
  /** Called with the new level (or null when the current one is tapped again). */
  onChange?: (level: FlowLevel | null) => void;
  /** Full-width row of equal cells. Default true. */
  block?: boolean;
}

/**
 * FlowScale — the period flow selector: four droplets deepening from spotting
 * to heavy (colors from the `--flow-*` ramp). Single-select, tap-to-toggle.
 * The centerpiece of the daily log sheet. Also exports `FLOW_LEVELS`.
 *
 * @startingPoint section="Tracking" subtitle="Flow intensity selector" viewport="360x120"
 */
export declare function FlowScale(props: FlowScaleProps): JSX.Element;
export declare const FLOW_LEVELS: { key: FlowLevel; label: string; color: string; drop: number }[];
