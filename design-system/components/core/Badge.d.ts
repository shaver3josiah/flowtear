import React from "react";

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  /** Color tone — cycle phases, plus neutral & good. Default "neutral". */
  tone?: "neutral" | "menstrual" | "follicular" | "fertile" | "ovulation" | "luteal" | "good";
  /** Show a leading dot in the tone color. */
  dot?: boolean;
}

/**
 * Badge — a small soft-tinted status label (optional leading dot). For inline
 * status like "Day 3", "Predicted", "Logged". For the larger phase indicator
 * with its own dot, use PhaseBadge.
 */
export declare function Badge(props: BadgeProps): JSX.Element;
