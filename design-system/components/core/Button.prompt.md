**Button** — the primary action pill; use for any tappable action, from the main "Log today" CTA to inline text actions.

```jsx
<Button>Log today</Button>
<Button variant="soft" iconLeft={<PlusIcon/>}>Add symptom</Button>
<Button variant="ghost" size="sm">Skip</Button>
<Button variant="deep" block>Start tracking</Button>
```

Variants: `primary` (strong pink CTA), `soft` (quiet fill), `ghost` (transparent), `deep` (dark high-emphasis). Sizes `sm|md|lg`. Fully capsule-shaped, scales down on press, themed shadow. Pass `disabled` for the inert state.
