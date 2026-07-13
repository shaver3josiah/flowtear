import React from "react";

export interface IconButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  /** Fill style. Default "soft". */
  variant?: "soft" | "ghost" | "primary";
  /** Diameter. Default "md" (44px — the min tap target). */
  size?: "sm" | "md" | "lg";
  /** Accessible label (icon-only buttons need one). */
  label?: string;
  /** The icon node. */
  children?: React.ReactNode;
}

/**
 * IconButton — a round, icon-only tap target for toolbars, calendar nav,
 * and close/overflow actions. Always pass `label` for accessibility.
 */
export declare function IconButton(props: IconButtonProps): JSX.Element;
