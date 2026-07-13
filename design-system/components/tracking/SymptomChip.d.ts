import React from "react";

export type SymptomKey =
  | "cramps" | "headache" | "bloating" | "fatigue" | "tenderBreasts"
  | "backPain" | "acne" | "moodSwings" | "nausea" | "insomnia" | "depressed";

export interface SymptomChipProps {
  /** Built-in symptom key — supplies the canonical label. */
  symptom?: SymptomKey | string;
  /** Override / custom label. */
  label?: string;
  /** Selected state (controlled). */
  selected?: boolean;
  /** Toggle handler. */
  onClick?: React.MouseEventHandler;
  /** Leading icon node (recommended: the Lucide glyph named in SYMPTOMS). */
  icon?: React.ReactNode;
  /** Size. Default "md". */
  size?: "sm" | "md";
}

/**
 * SymptomChip — a selectable chip bound to the built-in symptom vocabulary
 * (cramps, headache, bloating, …). Lay several out in a wrap for the log sheet.
 * Exports `SYMPTOMS`, the full list with recommended Lucide icon names.
 */
export declare function SymptomChip(props: SymptomChipProps): JSX.Element;
export declare const SYMPTOMS: { key: SymptomKey; label: string; icon: string }[];
