**SegmentedTabs** — the capsule tab switcher from the Bloom KTabBar; use for in-page view switching (Week/Month, insight ranges, log categories).

```jsx
<SegmentedTabs
  options={[{value:"month",label:"Month"},{value:"year",label:"Year"}]}
  value={view} onChange={setView} block />
```

Controlled via `value`/`onChange`. Options may be plain strings or `{value,label,icon}`. Soft track, strong-pink active pill. `block` makes it full-width with equal segments.
