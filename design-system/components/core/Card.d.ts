import React from "react";

export interface CardProps extends React.HTMLAttributes<HTMLElement> {
  /** Surface treatment. `plain` = white + shadow (default). */
  variant?: "plain" | "soft" | "accent" | "outline";
  /** Add hover lift + pointer for tappable cards. */
  interactive?: boolean;
  /** Render as a different element (e.g. "button", "a", "section"). */
  as?: keyof JSX.IntrinsicElements;
  /** Override the default 18px interior padding. */
  padding?: number | string;
}

/**
 * Card — the fundamental surface: white, soft themed shadow, 22px corners
 * (from the Bloom Card). Everything in the app sits on cards. `soft`/`accent`
 * for quiet inner panels, `outline` for a hairline-bordered variant.
 *
 * @startingPoint section="Core" subtitle="Surface card variants" viewport="360x200"
 */
export declare function Card(props: CardProps): JSX.Element;
