import React from "react";

export interface WordmarkProps extends React.HTMLAttributes<HTMLSpanElement> {
  /** `display` = Playfair lockup (default). `script` = Great Vibes flourish. */
  variant?: "display" | "script";
  /** Font size in px for the text; the mark scales with it. Default 28. */
  size?: number;
  /** Show the FlowerMark before the text. Default true. */
  showMark?: boolean;
  /** Override the word. Default "Flowtier". */
  text?: string;
}

/**
 * Wordmark — the Flowtier name in brand type with the bloom mark. Flowtier has
 * no logo image asset; this lockup is the logo. Use `display` for headers &
 * nav, `script` for splash / welcome moments.
 *
 * @startingPoint section="Brand" subtitle="Flowtier logo lockup" viewport="360x120"
 */
export declare function Wordmark(props: WordmarkProps): JSX.Element;
