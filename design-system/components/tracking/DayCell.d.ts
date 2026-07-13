import React from "react";
import { FlowLevel } from "./FlowScale";

export interface DayCellProps extends React.HTMLAttributes<HTMLElement> {
  /** Day-of-month number. */
  day: number;
  /** Day classification. */
  state?: "period" | "predicted" | "fertile" | "ovulation" | null;
  /** Logged flow — draws a small intensity dot. */
  flow?: FlowLevel | "none" | null;
  /** Ring the cell as today. */
  today?: boolean;
  /** Filled selected state (strong pink). */
  selected?: boolean;
  /** Dim as an out-of-month day. */
  muted?: boolean;
  /** Diameter in px. Default 40. */
  size?: number;
  /** Makes the cell a button. */
  onClick?: React.MouseEventHandler;
}

/**
 * DayCell — one day in the month calendar. Combines a state wash (period /
 * predicted / fertile / ovulation), a today ring, selection, and an optional
 * flow dot. Lay 7-wide in a CSS grid to build the calendar.
 */
export declare function DayCell(props: DayCellProps): JSX.Element;
