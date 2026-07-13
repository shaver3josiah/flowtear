import React from "react";

export interface FlowtierLogoProps extends React.SVGAttributes<SVGSVGElement> {
  /** Rendered width & height in px. Default 96. */
  size?: number;
  /** Accessible label. Default "Flowtier". */
  title?: string;
}

/**
 * FlowtierLogo — the Flowtier brand mark: a smiling pink alarm clock (time +
 * cycles, made friendly). Theme-tinted via tokens. Use as the app icon, splash
 * mark, onboarding hero, or beside the Wordmark. For the plain bloom motif use
 * FlowerMark instead.
 *
 * @startingPoint section="Brand" subtitle="The Flowtier clock logo" viewport="260x260"
 */
export declare function FlowtierLogo(props: FlowtierLogoProps): JSX.Element;
