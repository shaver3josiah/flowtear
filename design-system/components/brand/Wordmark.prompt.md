**Wordmark** — the Flowtier name in brand type with the bloom mark; this lockup is the logo (there is no image asset).

```jsx
<Wordmark />                              {/* Playfair lockup with mark */}
<Wordmark variant="script" size={44} />  {/* Great Vibes, for splash/welcome */}
<Wordmark showMark={false} size={22} />  {/* text-only, e.g. compact headers */}
```

`display` (Playfair Display 600) is the everyday lockup; `script` (Great Vibes) is reserved for splash and affectionate moments. Color comes from `--deep`.
