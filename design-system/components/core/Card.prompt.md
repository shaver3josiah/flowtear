**Card** — the fundamental surface; everything in the app sits on one.

```jsx
<Card><h3>Your cycle</h3>…</Card>
<Card variant="soft" padding={14}>Quiet inner panel</Card>
<Card variant="outline">Hairline-bordered</Card>
<Card interactive onClick={…}>Tappable card with hover lift</Card>
```

`plain` is white with a soft themed shadow and 22px corners. `soft`/`accent` are shadowless tinted panels for nesting inside a plain card; `outline` swaps shadow for a `--line` border. `interactive` adds hover-lift + pointer.
