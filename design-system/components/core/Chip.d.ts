import React from "react";

export interface ChipProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  /** Selected (filled strong-pink) state. */
  selected?: boolean;
  /** Size. Default "md". */
  size?: "sm" | "md";
  /** Optional leading icon node. */
  icon?: React.ReactNode;
}

/**
 * Chip — a selectable pill for multi-select vocabularies (symptoms, moods,
 * tags). Renders as a toggle button (`aria-pressed`); drive `selected`
 * yourself. For the built-in symptom set with icons, use SymptomChip instead.
 */
export declare function Chip(props: ChipProps): JSX.Element;
