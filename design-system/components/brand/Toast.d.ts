import React from "react";

export interface ToastProps extends React.HTMLAttributes<HTMLDivElement> {
  /** Bold deep-colored headline. */
  title?: string;
  /** Muted supporting line (truncates to keep the toast compact). */
  message?: string;
  /** Replace the leading FlowerMark with a custom icon node. */
  icon?: React.ReactNode;
}

/**
 * Toast — the flower-headed notice from the Bloom family: white card, bloom
 * mark, deep title, muted message. For saves, reminders and gentle
 * confirmations. Mount it yourself in a fixed top region; it has no timer.
 */
export declare function Toast(props: ToastProps): JSX.Element;
