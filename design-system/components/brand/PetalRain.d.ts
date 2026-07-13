import React from "react";

export interface PetalRainProps extends React.HTMLAttributes<HTMLDivElement> {
  /** How many petals drift at once. Default 14. */
  count?: number;
  /** Stacking order within the positioned parent. Default 0. */
  zIndex?: number;
}

/**
 * PetalRain — the signature "magical" layer: soft rose petals drifting down
 * (from the Bloom petal curtain). Drop it inside a `position: relative`/`absolute`
 * container (splash, Today hero, a celebration) — it fills the parent, ignores
 * pointer events, and renders nothing under `prefers-reduced-motion`.
 */
export declare function PetalRain(props: PetalRainProps): JSX.Element;
