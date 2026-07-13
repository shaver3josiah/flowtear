import React from "react";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  /** Emphasis. `primary` (strong pink) is the default CTA. */
  variant?: "primary" | "deep" | "soft" | "ghost";
  /** Height & padding. Default "md" (46px). */
  size?: "sm" | "md" | "lg";
  /** Stretch to the container width. */
  block?: boolean;
  /** Icon node rendered before the label. */
  iconLeft?: React.ReactNode;
  /** Icon node rendered after the label. */
  iconRight?: React.ReactNode;
}

/**
 * Button — the primary action pill: full-capsule radius, springy press, soft
 * themed shadow. `primary` for the main action, `soft` for secondary, `ghost`
 * for tertiary/inline, `deep` for high-emphasis dark moments.
 *
 * @startingPoint section="Core" subtitle="Action buttons in every variant" viewport="360x220"
 */
export declare function Button(props: ButtonProps): JSX.Element;
