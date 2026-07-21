# Scientific Theme System

All themes use the same slide markup and chart semantics. Switching themes changes only CSS custom properties. `Institutional Blue` is the default.

## Shared variable contract

Every theme must define:

- `--stage-bg`, `--slide-bg`, `--bg`, `--surface`
- `--text`, `--muted`, `--accent`, `--warning`, `--rule`
- `--font-heading`, `--font-body`
- `--title-size`, `--body-size`, `--citation-size`
- `--chart-1` through `--chart-6`

The chart palette is ordered, color-blind-aware, and semantically stable across a deck. A treatment group never changes color between slides. Add direct labels, shapes, or line styles when color alone would carry meaning.

## Institutional Blue — default

Formal, neutral, and reliable for defenses, grant review, institutional reports, and mixed-discipline audiences.

```css
:root,
[data-theme="institutional-blue"] {
  --stage-bg: #d9e0e5;
  --slide-bg: #f4f7f8;
  --bg: #f4f7f8;
  --surface: #e6edf0;
  --text: #183149;
  --muted: #5f7180;
  --accent: #397775;
  --warning: #9a514b;
  --rule: #c5d1d7;
  --font-heading: "Source Sans 3", sans-serif;
  --font-body: "Source Sans 3", sans-serif;
  --title-size: 64px;
  --body-size: 30px;
  --citation-size: 20px;
  --chart-1: #285b75;
  --chart-2: #4c817d;
  --chart-3: #b07a45;
  --chart-4: #765b82;
  --chart-5: #758993;
  --chart-6: #a95454;
}
```

## Journal Ivory

Warm, editorial, and reading-oriented. Suitable for literature synthesis, interdisciplinary review, and asynchronous circulation.

```css
[data-theme="journal-ivory"] {
  --stage-bg: #d8d2c7;
  --slide-bg: #f4f0e7;
  --bg: #f4f0e7;
  --surface: #e9e1d5;
  --text: #24323d;
  --muted: #6f706d;
  --accent: #8b4547;
  --warning: #a15d34;
  --rule: #d1c6b7;
  --font-heading: "Source Serif 4", serif;
  --font-body: "Source Sans 3", sans-serif;
  --title-size: 62px;
  --body-size: 30px;
  --citation-size: 20px;
  --chart-1: #345b6c;
  --chart-2: #9a4d50;
  --chart-3: #a68143;
  --chart-4: #6e6683;
  --chart-5: #6b827d;
  --chart-6: #8d6b56;
}
```

## Field Sage

Calm and observational. Suitable for life sciences, medicine, ecology, and field research. Any paper-grid texture must be faint enough that it cannot reduce figure contrast.

```css
[data-theme="field-sage"] {
  --stage-bg: #d8dbd2;
  --slide-bg: #f2f1ea;
  --bg: #f2f1ea;
  --surface: #e3e7de;
  --text: #2b4238;
  --muted: #6b786f;
  --accent: #49675a;
  --warning: #9a5f46;
  --rule: #cbd2c8;
  --font-heading: "Source Serif 4", serif;
  --font-body: "Source Sans 3", sans-serif;
  --title-size: 62px;
  --body-size: 30px;
  --citation-size: 20px;
  --chart-1: #3f6b5a;
  --chart-2: #a06147;
  --chart-3: #55758b;
  --chart-4: #84714e;
  --chart-5: #76657b;
  --chart-6: #8b514f;
}
```

## Dark Lecture

Restrained dark-room theme for conference projection. It uses no neon, glow, or luminous decoration. Re-check every imported figure against the dark background; do not invert a figure when inversion changes semantic colors.

```css
[data-theme="dark-lecture"] {
  --stage-bg: #091016;
  --slide-bg: #152029;
  --bg: #152029;
  --surface: #1e2d36;
  --text: #dce6e8;
  --muted: #9babb0;
  --accent: #7aa4a8;
  --warning: #d0a27c;
  --rule: #334650;
  --font-heading: "Source Sans 3", sans-serif;
  --font-body: "Source Sans 3", sans-serif;
  --title-size: 64px;
  --body-size: 30px;
  --citation-size: 20px;
  --chart-1: #7fb2b3;
  --chart-2: #d0a27c;
  --chart-3: #8da2c3;
  --chart-4: #b19ab8;
  --chart-5: #a8b17e;
  --chart-6: #c78686;
}
```

## Preview rule

Generate four previews using the same authentic result or method slide. Show Institutional Blue first and label it recommended outside the slide. A title-only preview is insufficient because it does not demonstrate figure, table, citation, and annotation readability.
