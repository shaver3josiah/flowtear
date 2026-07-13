**FlowScale** — the period flow selector; the centerpiece of the daily log sheet.

```jsx
<FlowScale value={flow} onChange={setFlow} />
```

Four droplets that deepen and grow across the `--flow-*` ramp: spotting → light → medium → heavy. Single-select and tap-to-toggle (tapping the active level clears it → `null`). Import `FLOW_LEVELS` for the same vocabulary in charts/legends.
