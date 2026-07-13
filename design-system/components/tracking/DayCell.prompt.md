**DayCell** — one day in the month calendar; lay 7-wide in a CSS grid.

```jsx
<DayCell day={12} state="period" flow="medium" />
<DayCell day={18} state="fertile" />
<DayCell day={20} state="ovulation" today />
<DayCell day={27} state="predicted" />
<DayCell day={14} selected onClick={...} />
```

States wash the cell in phase tints: `period` (menstrual), `predicted` (dashed forecast), `fertile`, `ovulation` (amber ring). `today` adds a pink ring, `selected` fills strong-pink, `muted` dims out-of-month days. A logged `flow` adds an intensity dot.
