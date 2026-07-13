import React from "react";
import { Chip } from "../core/Chip.jsx";

/* The built-in symptom vocabulary, verbatim from the source trackers. `icon` is
   the recommended Lucide glyph name (the system's icon set — see README). */
export const SYMPTOMS = [
  { key: "cramps", label: "Cramps", icon: "zap" },
  { key: "headache", label: "Headache", icon: "brain" },
  { key: "bloating", label: "Bloating", icon: "circle-dot" },
  { key: "fatigue", label: "Fatigue", icon: "battery-low" },
  { key: "tenderBreasts", label: "Tender breasts", icon: "heart" },
  { key: "backPain", label: "Back pain", icon: "person-standing" },
  { key: "acne", label: "Acne", icon: "sparkle" },
  { key: "moodSwings", label: "Mood swings", icon: "cloud-sun" },
  { key: "nausea", label: "Nausea", icon: "waves" },
  { key: "insomnia", label: "Insomnia", icon: "moon" },
  { key: "depressed", label: "Low mood", icon: "cloud-rain" },
];

/**
 * SymptomChip — a selectable chip bound to the built-in symptom vocabulary.
 * Pass a `symptom` key for the canonical label, or `label` to override. Provide
 * `icon` (a Lucide node) for the leading glyph.
 */
export function SymptomChip({ symptom, label, selected = false, onClick, icon, size = "md", ...rest }) {
  const meta = SYMPTOMS.find((s) => s.key === symptom);
  return (
    <Chip selected={selected} onClick={onClick} size={size} icon={icon} {...rest}>
      {label || (meta && meta.label) || symptom}
    </Chip>
  );
}
