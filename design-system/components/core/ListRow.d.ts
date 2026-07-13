import React from "react";

export interface ListRowProps extends React.HTMLAttributes<HTMLElement> {
  /** Leading icon node (sits in a soft rounded square). */
  icon?: React.ReactNode;
  /** Primary label. */
  title?: React.ReactNode;
  /** Muted secondary line. */
  subtitle?: React.ReactNode;
  /** Trailing slot — a Switch, chevron, or value text. */
  trailing?: React.ReactNode;
  /** When provided, the row renders as a button with hover state. */
  onClick?: React.MouseEventHandler;
}

/**
 * ListRow — a settings / reminders row: rounded leading icon, title + subtitle,
 * trailing control. Stack several inside a Card for a settings group. Becomes a
 * button (with hover) when `onClick` is set.
 *
 * @startingPoint section="Core" subtitle="Settings & reminder rows" viewport="380x220"
 */
export declare function ListRow(props: ListRowProps): JSX.Element;
