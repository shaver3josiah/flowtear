import React from "react";

export type CyclePhase = "menstrual" | "follicular" | "fertile" | "ovulation" | "luteal";

export interface CycleRingProps extends React.HTMLAttributes<HTMLDivElement> {
  /** Current day of the cycle, 1-based. */
  cycleDay?: number;
  /** Average cycle length in days. Default 28. */
  cycleLength?: number;
  /** Average period (bleed) length in days. Default 5. */
  periodLength?: number;
  /** Diameter in px. Default 260. */
  size?: number;
  /** Let her spin the dial like a fidget spinner (drag + inertial decay). Disabled under reduced-motion. */
  spinnable?: boolean;
  /** Custom center content — overrides the default day/phase readout. */
  children?: React.ReactNode;
}

/**
 * CycleRing — the hero cycle visualization: a soft donut with the bleed days,
 * fertile window and ovulation marked in phase colors and a knob on today.
 * Derives the fertile window & ovulation from cycleLength/periodLength using the
 * standard 14-day-luteal model. Pass `children` for a custom center (e.g. a
 * "6 days to your next bloom" countdown).
 *
 * Also exports `phaseForDay(day, cycleLength, periodLength): CyclePhase`.
 *
 * @startingPoint section="Tracking" subtitle="The hero cycle ring" viewport="320x320"
 */
export declare function CycleRing(props: CycleRingProps): JSX.Element;
export declare function phaseForDay(day: number, cycleLength: number, periodLength: number): CyclePhase;
