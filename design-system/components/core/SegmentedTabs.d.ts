import React from "react";

export interface SegmentOption {
  value: string;
  label: string;
  icon?: React.ReactNode;
}

export interface SegmentedTabsProps extends Omit<React.HTMLAttributes<HTMLDivElement>, "onChange"> {
  /** Options — strings, or {value,label,icon} objects. */
  options: (SegmentOption | string)[];
  /** Currently selected value (controlled). */
  value: string;
  /** Called with the new value on select. */
  onChange?: (value: string) => void;
  /** Stretch to fill the container width, segments equal-width. */
  block?: boolean;
}

/**
 * SegmentedTabs — the capsule tab switcher from the Bloom KTabBar: a soft
 * track with a strong-pink active pill. Use for in-page view switching
 * (e.g. Week / Month, or Insights ranges).
 *
 * @startingPoint section="Core" subtitle="Capsule segmented control" viewport="360x120"
 */
export declare function SegmentedTabs(props: SegmentedTabsProps): JSX.Element;
