**StatTile** — a compact stat panel; grid these for the Insights summary.

```jsx
<div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:10}}>
  <StatTile value="28" unit="days" label="Average cycle" />
  <StatTile value="5" unit="days" label="Average period" />
</div>
```

Big Playfair `value` with an optional small `unit`, a muted `label`, and an optional `icon`. `tone`: `soft` (default tinted panel), `accent`, or `card` (white with shadow).
