**CycleRing** — the hero cycle visualization; the centerpiece of the Today screen.

```jsx
<CycleRing cycleDay={14} cycleLength={28} periodLength={5} size={280} />

{/* custom center — a countdown */}
<CycleRing cycleDay={22} cycleLength={29}>
  <span style={{fontFamily:"var(--font-body)",fontSize:"var(--text-xs)",letterSpacing:".08em",textTransform:"uppercase",color:"var(--muted)"}}>next bloom in</span>
  <span style={{fontFamily:"var(--font-display)",fontSize:56,color:"var(--deep)"}}>6</span>
  <span style={{fontFamily:"var(--font-body)",color:"var(--muted)"}}>days</span>
</CycleRing>
```

Marks bleed days (menstrual), the fertile window, and ovulation on a soft donut, with a knob on today. Phase colors come from the `--phase-*` tokens. The helper `phaseForDay(day,cycleLength,periodLength)` returns the phase for any day.
