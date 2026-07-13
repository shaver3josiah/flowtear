**FlowerMark** — the Flowtier bloom, the brand's signature flower motif; use it as the logo mark, an empty-state flourish, or a loading indicator.

```jsx
<FlowerMark size={64} />
<FlowerMark size={40} spin />        {/* slow decorative rotation */}
<FlowerMark size={48} breathe />     {/* ambient loading pulse */}
```

Pure SVG, colored entirely from theme tokens (`--primary`, `--primary-strong`, `--flower-center`), so it re-tints automatically with the active theme preset. No fixed colors — never hard-code a fill over it.
