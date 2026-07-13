**Switch** — the settings/reminder toggle; most often the trailing control of a ListRow.

```jsx
<Switch checked={on} onChange={setOn} label="Period reminders" />
```

Controlled via `checked`/`onChange`. Strong-pink track when on, spring-animated knob. `role="switch"` for accessibility — always pass `label` when it stands alone.
