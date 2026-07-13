**PetalRain** — the signature magical layer of drifting rose petals; use it on the splash, the Today hero, or a celebration moment.

```jsx
<div style={{position:"relative"}}>
  <PetalRain count={16} />
  …your content…
</div>
```

Absolutely fills its positioned parent, `pointer-events:none`, and auto-disables under `prefers-reduced-motion`. Petals are tinted from `--primary` / `--primary-strong` / `--deep`, so they follow the theme. Keep counts modest (12–18) for a soft, not busy, feel.
