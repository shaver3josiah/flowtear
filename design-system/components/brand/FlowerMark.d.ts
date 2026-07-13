import React from "react";

export interface FlowerMarkProps extends React.SVGAttributes<SVGSVGElement> {
  /** Rendered width & height in px. Default 48. */
  size?: number;
  /** Slowly rotate forever (decorative; respects reduced-motion via tokens). */
  spin?: boolean;
  /** Gentle scale "breathing" loop — used for loading / ambient states. */
  breathe?: boolean;
  /** Accessible label. Default "Flowtier". */
  title?: string;
}

/**
 * FlowerMark — the Flowtier bloom, the brand's signature motif.
 * A procedural rose of three petal rings (theme pinks) around a gold center,
 * recreated from the Bloom family's FlowerLogo. Use anywhere a logo mark,
 * empty-state flourish, or loading indicator is wanted.
 *
 * @startingPoint section="Brand" subtitle="The signature Flowtier bloom" viewport="240x240"
 */
export declare function FlowerMark(props: FlowerMarkProps): JSX.Element;
