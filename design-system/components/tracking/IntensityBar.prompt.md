**IntensityBar** — a labeled horizontal bar for breakdown charts; stack several in a Card to make an insights chart.

```jsx
<Card>
  <h3>Flow this cycle</h3>
  <IntensityBar label="Light"  value={0.2} color="var(--flow-light)"  meta="1 day" />
  <IntensityBar label="Medium" value={0.6} color="var(--flow-medium)" meta="3 days" />
  <IntensityBar label="Heavy"  value={0.4} color="var(--flow-heavy)"  meta="2 days" />
</Card>
```

`value` is 0–1. Use the `--flow-*` ramp for flow breakdowns and `--phase-*` / semantic colors elsewhere. The fill animates on mount with the signature easing.
