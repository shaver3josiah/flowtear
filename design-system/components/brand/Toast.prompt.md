**Toast** — the flower-headed notice from the Bloom family; use for saves, reminders, and gentle confirmations.

```jsx
<Toast title="Logged, love." message="Day 2 · Medium flow saved to today." />
<Toast title="Reminder set" message="We'll nudge you 2 days before your next bloom." />
```

White surface, `--radius` corners, soft drop shadow, FlowerMark on the left. Title is `--deep`, message is `--muted` and truncates. No auto-dismiss — mount and unmount it yourself (e.g. in a fixed top slot).
