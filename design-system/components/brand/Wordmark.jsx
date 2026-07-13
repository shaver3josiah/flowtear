import React from "react";
import { FlowerMark } from "./FlowerMark.jsx";

/**
 * Wordmark — the Flowtier name set in the brand type, with the bloom mark.
 * `display` uses Playfair Display (the everyday lockup); `script` uses Great
 * Vibes (splash screens, affectionate moments). There is no logo image asset —
 * the wordmark IS the logo.
 */
export function Wordmark({ variant = "display", size = 28, showMark = true, text = "Flowtier", style, className, ...rest }) {
  const isScript = variant === "script";
  return (
    <span
      className={className}
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: isScript ? "0.4em" : "0.55em",
        color: "var(--deep)",
        lineHeight: 1,
        ...style,
      }}
      {...rest}
    >
      {showMark && <FlowerMark size={isScript ? size * 1.15 : size * 1.0} aria-hidden="true" />}
      <span
        style={{
          fontFamily: isScript ? "var(--font-script)" : "var(--font-display)",
          fontWeight: isScript ? 400 : 600,
          fontSize: size,
          letterSpacing: isScript ? "0.01em" : "var(--tracking-tight)",
        }}
      >
        {text}
      </span>
    </span>
  );
}
