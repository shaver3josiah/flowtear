**Chip** — a selectable pill for multi-select vocabularies (moods, tags, filters); toggles to a filled strong-pink selected state.

```jsx
<Chip selected={m==="calm"} onClick={()=>setMood("calm")} icon={<Smile/>}>Calm</Chip>
<Chip size="sm">All</Chip>
```

Controlled — you own `selected`. Renders a real toggle button with `aria-pressed`. For period symptoms specifically, prefer `SymptomChip` (it maps the built-in symptom set to icons).
