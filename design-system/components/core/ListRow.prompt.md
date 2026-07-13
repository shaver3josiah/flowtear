**ListRow** — a settings / reminders row; stack several inside a Card for a settings group.

```jsx
<ListRow icon={<Bell/>} title="Period reminder"
  subtitle="2 days before" trailing={<Switch checked={on} onChange={setOn}/>} />
<ListRow icon={<Palette/>} title="Theme" trailing={<>Cherry <ChevronRight/></>} onClick={openThemes} />
```

Leading icon sits in a soft rounded square (`--primary-strong` glyph). Provide `onClick` to make the whole row a tappable button with a hover wash. Trailing slot takes a Switch, chevron, or value.
