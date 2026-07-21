---
name: frontend-slides-science
description: Convert Markdown, Word, PDF, PPTX, or research notes into logically structured, evidence-led HTML scientific reports with restrained themes, readable figures, and self-contained export tooling.
---

# Frontend Slides Science

Create fixed-stage HTML presentations for scientific reports. Scientific argument, source fidelity, figure readability, and uncertainty outrank visual novelty.

## Core principles

1. **Argument before layout** — Establish the question, gap, hypothesis, method, evidence, interpretation, limitations, and conclusion before designing slides.
2. **Evidence before decoration** — Figures, tables, controls, effect sizes, and uncertainty receive the visual emphasis.
3. **One defensible claim per slide** — Result-slide titles state findings; they do not say only “Results,” “Analysis,” or a chart name.
4. **No invention** — Never add absent results, methods, statistics, citations, causal claims, or next steps.
5. **Restrained visual system** — Use quiet colors, 28 px or larger body text, 20 px or larger citations, limited ornament, and short motion only when it carries reasoning.
6. **Fixed 16:9 stage** — Author every slide at 1920×1080 and uniformly scale the stage to the viewport. Never reflow slides for phones.
7. **Self-contained operation** — Read templates, references, and scripts only from this skill directory. Use local scripts for export, deployment, and PPTX extraction.

## Required local files

Read each file only when its phase requires it:

| File | Purpose | Read when |
|---|---|---|
| `references/content-workflow.md` | Claim audit, narrative, outline, source failure policy | Before outlining |
| `SCIENCE_THEMES.md` | Four scientific theme recipes | Before theme previews |
| `references/figure-guidelines.md` | Figures, tables, statistics, accessibility | Before generation |
| `html-template.md` | Complete HTML/CSS/JS architecture | Before generation |
| `viewport-base.css` | Mandatory fixed-stage CSS | Before generation; include in full |
| `animation-patterns.md` | Permitted restrained motion | Before generation |
| `references/verification-checklist.md` | Delivery-blocking verification gates | After generation |
| `scripts/extract-pptx.py` | PPTX text, notes, and image extraction | PPTX conversion only |
| `scripts/export-pdf.sh` | PDF export | When requested or used for verification |
| `scripts/deploy.sh` | Vercel deployment | When requested |

## Phase 0 — Detect the mode

Choose one mode from the user’s material and request:

- **Mode A: New scientific report** — Topic, notes, or incomplete content.
- **Mode B: Document-to-slides** — Markdown, Word `.docx`, or PDF source.
- **Mode C: PPTX conversion** — Preserve source content, notes, figures, and ordering unless the user explicitly approves restructuring.
- **Mode D: Existing HTML enhancement** — Improve scientific structure, readability, or theme without losing source-backed content.

For Mode D, inventory existing slide types, content density, figure count, controls, and stage model before editing. Split crowded slides rather than adding content to an already full 1920×1080 stage.

## Phase 1 — Discover purpose and material

Ask all applicable questions together through the native structured-question UI:

1. **Purpose** — Conference talk / Group meeting or progress report / Defense or review / Reading-first report.
2. **Audience** — Specialist / Mixed scientific / General technical.
3. **Length** — 5–10 / 10–20 / 20+ slides or a fixed time limit.
4. **Source readiness** — Complete document / Draft and figures / Notes only.
5. **Density** — Speaker-led / Group-discussion / Reading-first.
6. **Language** — Preserve source language or translate; never silently translate terminology.

If the user supplied a document, do not ask them to paste content already available through document reading tools.

### Density behavior

- **Speaker-led:** One claim and one main figure per slide; 2–4 support statements; more slides rather than smaller text.
- **Group-discussion:** Preserve controls, method choices, ablations, failures, and unresolved decisions.
- **Reading-first:** Add self-contained explanation and citations; split dense material across additional slides.

## Phase 2 — Inventory and audit sources

Read `references/content-workflow.md`.

### Markdown / plain text

Read heading hierarchy, prose, lists, tables, code blocks, citations, and image references. Preserve explicit section and figure identifiers.

### Word `.docx`

Use the host document reader to extract headings, paragraphs, tables, figures, and captions. If hierarchy, equations, tracked changes, tables, or images are missing from extraction, report exactly what is incomplete before outlining.

### PDF

Use the host document reader and retain page anchors. Inventory figures, captions, tables, equations, and references. If the PDF is encrypted, is a scan without OCR, or yields materially incomplete text, stop and request an accessible or OCRed version. Do not summarize fragments as though extraction were complete.

### PPTX

Run the local extractor:

```bash
python scripts/extract-pptx.py <input.pptx> <output-dir>
```

Inspect `extracted-slides.json`, speaker notes, and every extracted image. Present source slide titles, content summaries, and image counts before conversion.

### Figures and other images

When image understanding is available, inspect each figure and record:

- what it shows;
- source page / figure identifier;
- axes, units, groups, uncertainty, and legend;
- whether labels remain readable at slide scale;
- whether it can be used intact, needs a faithful crop, or is unusable;
- any discrepancy between figure and surrounding text.

Never infer numeric values from a raster figure when the document provides exact values elsewhere.

### Claim audit

Build the internal claim record specified in `references/content-workflow.md`. Verify wording, numbers, units, sample sizes, group names, statistical tests, uncertainty, and source locations. Preserve missing and conflicting records for user resolution.

## Phase 3 — Build and confirm the scientific narrative

Use this default logic:

1. Context
2. Gap
3. Question / Hypothesis
4. Approach
5. Evidence
6. Interpretation
7. Limitations
8. Conclusion / Next Step

Do not create an empty section to satisfy the template. Do not promote an interpretation into a source finding.

Create a complete slide outline before HTML. For each page show:

- slide number and role;
- conclusion-style title;
- evidence, figure, or table;
- source page / section / figure identifier;
- layout recommendation;
- missing or conflicting inputs.

Ask the user to approve or revise the complete outline. Do not generate the full deck before approval.

## Phase 4 — Scientific theme discovery

Read `SCIENCE_THEMES.md`.

Generate four single-slide previews with the same authentic result or method content:

1. **Institutional Blue** — default and recommended.
2. **Journal Ivory**.
3. **Field Sage**.
4. **Dark Lecture**.

Preview requirements:

- Use a real result or method slide, not a title-only slide.
- Include a conclusion title, figure or faithful figure stand-in, uncertainty or method labels, interpretation, and source footer.
- Keep visible text authentic to the report. Do not put “preview,” file paths, design notes, template names, or internal metadata on the slide.
- Label theme names outside the slide only.
- Keep all four previews at fixed 1920×1080 proportions.

Ask the user to select a theme or specify a mix. Theme mixing may combine typography and palette, but it must still produce one complete variable block with accessible chart colors.

## Phase 5 — Generate the deck

Before generation, read:

- `html-template.md`;
- `viewport-base.css`;
- `animation-patterns.md`;
- `references/figure-guidelines.md`.

### Output contract

- One HTML entry with inline CSS and JavaScript.
- Include the full contents of `viewport-base.css` in the style block.
- With few or no external figures, the HTML may be fully self-contained.
- With numerous local figures, use a sibling `assets/` directory and relative paths.
- Use web fonts declared in the document; provide sensible serif / sans-serif fallbacks without relying on another package.
- Add clear section comments for theme, reset, fixed stage, slide layouts, motion, controls, controller, editor, and content-specific components.
- Preserve speaker notes in `.speaker-notes` elements.
- Keep navigation and edit controls outside `.deck-stage`.

### Required slide visibility model

Slides use `.active` and `.visible` with `visibility`, `opacity`, and `pointer-events`. Do not switch slides with `display: none` / `display: block`; layout classes can override display and expose every slide.

### Standard slide types

Use `data-slide-type` with these values:

- `title` — title, author, institution, date; no cinematic typography.
- `question` — context → gap → precise question.
- `study-design` — subjects, conditions, controls, sequence, endpoints.
- `method` — workflow, model, assumptions, parameters.
- `result` — conclusion title + primary figure + uncertainty + interpretation + source.
- `comparison` — common scale, explicit baseline, directly labeled differences.
- `limitation` — limitation, consequence, mitigation or unresolved status.
- `conclusion` — 2–4 evidence-backed conclusions; no new evidence.
- `references` — complete and readable citations.
- `appendix` — supplemental methods and results.

### Typography and density

- Body text: at least 28 px at 1920×1080.
- Captions and citations: at least 20 px.
- Result title: typically 52–68 px, long enough to state the finding without dominating the evidence.
- One main figure per slide, or two panels only for direct comparison.
- Split overflowing tables, multi-panel figures, or long arguments across additional slides.

### Motion

Use no motion by default for reading-first reports. Otherwise use the short fades from `animation-patterns.md`. Sequential reveal is allowed only when sequence communicates reasoning. Never use particles, parallax, glow, bounce, cursor trails, 3D tilt, looping motion, or animated numbers.

## Phase 6 — Verify before delivery

Read `references/verification-checklist.md` and execute every gate.

### Content checks

- Reconcile each slide claim, number, unit, sample size, statistic, and figure identifier against the claim record.
- Confirm that limitations and conflicts remain visible.
- Confirm that interpretations are labeled and no unsupported conclusion was introduced.

### Browser checks

Run the deck in a real browser. Verify:

- 1280×720 viewport;
- one phone viewport;
- fixed 16:9 stage with uniform scale and no responsive reflow;
- no text overflow, clipped citations, or geometric panel overlap;
- readable axes, legends, units, uncertainty, and direct labels;
- Arrow, Space, Page Up / Down, Home, End, touch, page count, notes, and edit mode;
- `prefers-reduced-motion` exposes every content element;
- no console errors.

A `scrollHeight` check alone is insufficient because grid panels can overlap without increasing scroll height.

### Source and asset checks

- Every local asset path is relative and loads over HTTP.
- Every evidence slide has a concise source footer.
- The references slide contains complete citations.
- Imported figures keep semantic colors and required annotations in the chosen theme.

Correct failures and repeat the same check. Do not deliver a deck with waived gates.

## Phase 7 — Deliver

Report:

- output path;
- selected theme;
- slide count;
- source files used;
- unresolved or missing source content;
- browser verification viewports and interactions;
- export status if performed.

Explain navigation: Arrow keys, Space, Page Up / Down, Home, End, swipe, `N` for notes, and `E` for edit mode. Text edits save to localStorage with Ctrl / Cmd + S.

## Phase 8 — Export or share

Use only the scripts bundled in this skill.

### PDF

```bash
bash scripts/export-pdf.sh <path-to-html> [output.pdf]
```

Verify that the script reports the expected `.slide` count and that the PDF page count matches. Animations become their final static state.

### Deploy

Prefer deploying the presentation folder when it contains `assets/`:

```bash
bash scripts/deploy.sh <path-to-presentation-folder>
```

A single HTML file is acceptable when all assets are embedded or its relative references can be collected by the script. After deployment, open the live URL and verify every figure.

## Enhancement rules

When modifying an existing scientific deck:

1. Count existing claims, figures, panels, and citations on each affected slide.
2. Locate each added claim in the source audit before editing.
3. If an addition would violate density or figure readability, split the slide.
4. Preserve the selected theme’s variable contract and group-color semantics.
5. Repeat content, browser, and export checks for every affected path.

Never solve overflow by continuously shrinking type, and never remove a caveat merely to recover space.
