import React from "react";
import { CyclePhase } from "./CycleRing";

export interface PhaseBadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  /** Which cycle phase to show. Default "follicular". */
  phase?: CyclePhase;
  /** Optional trailing detail, e.g. "Day 3" or "2 days left". */
  subtitle?: React.ReactNode;
}

/**
 * PhaseBadge — the prominent current-phase indicator: a phase-tinted pill with
 * a color dot, phase name, and optional subtitle. Use on the Today header and
 * atop the log sheet. For tiny inline status use Badge instead.
 */
export declare function PhaseBadge(props: PhaseBadgeProps): JSX.Element;
