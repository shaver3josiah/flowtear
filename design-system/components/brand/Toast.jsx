import React from "react";
import { FlowerMark } from "./FlowerMark.jsx";

/**
 * Toast — the gentle flower-headed notice from the Bloom family. A white card
 * with the bloom mark, a deep title, and a muted message. Used for saves,
 * reminders, and little affectionate confirmations.
 */
export function Toast({ title, message, icon, style, className, ...rest }) {
  return (
    <div
      className={className}
      role="status"
      style={{
        display: "flex",
        alignItems: "center",
        gap: "12px",
        padding: "14px 16px",
        background: "var(--surface)",
        borderRadius: "var(--radius)",
        boxShadow: "0 10px 24px -8px var(--shadow)",
        maxWidth: "380px",
        ...style,
      }}
      {...rest}
    >
      <span style={{ flex: "none", display: "grid", placeItems: "center" }}>
        {icon || <FlowerMark size={34} aria-hidden="true" />}
      </span>
      <span style={{ display: "flex", flexDirection: "column", gap: "2px", minWidth: 0 }}>
        {title && (
          <span
            style={{
              fontFamily: "var(--font-body)",
              fontWeight: "var(--weight-semibold)",
              fontSize: "var(--text-base)",
              color: "var(--deep)",
            }}
          >
            {title}
          </span>
        )}
        {message && (
          <span
            style={{
              fontFamily: "var(--font-body)",
              fontSize: "var(--text-sm)",
              color: "var(--muted)",
              lineHeight: "var(--leading-snug)",
              overflow: "hidden",
              textOverflow: "ellipsis",
            }}
          >
            {message}
          </span>
        )}
      </span>
    </div>
  );
}
