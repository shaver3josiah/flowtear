import React from "react";

export interface SwitchProps extends Omit<React.ButtonHTMLAttributes<HTMLButtonElement>, "onChange"> {
  /** On/off state (controlled). */
  checked?: boolean;
  /** Called with the next boolean when toggled. */
  onChange?: (next: boolean) => void;
  /** Accessible label. */
  label?: string;
}

/**
 * Switch — the settings/reminder toggle: soft track that fills strong-pink when
 * on, knob springs across. Controlled. Commonly the trailing control in a
 * ListRow (reminders, preferences).
 */
export declare function Switch(props: SwitchProps): JSX.Element;
