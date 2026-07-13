**SymptomChip** — a selectable chip bound to the built-in symptom vocabulary; lay several in a flex-wrap for the log sheet.

```jsx
import { SYMPTOMS } from ".../SymptomChip.jsx";
{SYMPTOMS.map(s =>
  <SymptomChip key={s.key} symptom={s.key}
    selected={picked.has(s.key)} onClick={()=>toggle(s.key)}
    icon={<i data-lucide={s.icon}/>} />
)}
```

Wraps `Chip` with the canonical labels for the 11 source symptoms. `SYMPTOMS` also carries the recommended Lucide icon name per symptom, so charts, legends and the picker stay consistent.
