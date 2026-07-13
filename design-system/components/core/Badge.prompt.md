**Badge** — a small soft-tinted status label; use for inline status like "Day 3", "Predicted", "Logged".

```jsx
<Badge>Day 3</Badge>
<Badge tone="fertile" dot>Fertile</Badge>
<Badge tone="good" dot>On track</Badge>
```

Tones: `neutral`, the five cycle phases (`menstrual|follicular|fertile|ovulation|luteal`), and `good`. Each is a soft background tint with matching text. For the prominent phase indicator, use `PhaseBadge` instead.
