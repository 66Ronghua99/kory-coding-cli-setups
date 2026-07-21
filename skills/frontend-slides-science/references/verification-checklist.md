# Scientific Deck Verification Checklist

A failed gate blocks delivery. Name the failed item, correct the source deck or content model, and repeat the same check. Do not waive failures through silent fallback.

## Gate 1 — Source fidelity

- [ ] Every material claim has a file and page / section source.
- [ ] Result numbers, signs, units, sample sizes, group names, and statistical quantities match the source.
- [ ] Figure and table identifiers match the source document.
- [ ] Interpretation is visually and verbally distinct from observed evidence.
- [ ] Conflicts, negative results, boundary conditions, and limitations remain visible.
- [ ] No unsupported claim, method detail, statistic, citation, or next step was added.
- [ ] Concise source footers appear on evidence slides; complete references appear at the end.

## Gate 2 — Layout

- [ ] The authored stage is exactly 1920×1080.
- [ ] The stage scales uniformly at 1280×720 and one phone viewport; slide content never reflows.
- [ ] Every slide stays within stage bounds with no clipped text, hidden citation, or panel overlap.
- [ ] Body text is at least 28 px; figure captions and citations are at least 20 px.
- [ ] Each result page has one main claim and no more than one main figure or one direct two-panel comparison.
- [ ] Dense content is split into additional slides instead of reduced below the typography limits.

## Gate 3 — Figure readability

- [ ] Axes, units, legends, sample sizes, and uncertainty definitions are readable.
- [ ] Direct comparisons use a common scale or clearly disclose scale differences.
- [ ] Group colors remain stable across slides.
- [ ] Meaning is not carried by red / green color alone.
- [ ] Source and adaptation labels are present.
- [ ] Cropping has not removed caveats, controls, or necessary annotations.
- [ ] Imported figures retain adequate contrast in the chosen theme and remain understandable in grayscale.

## Gate 4 — Runtime and export

- [ ] `.active` / `.visible` controls slide visibility; slide switching does not use layout-breaking display toggles.
- [ ] Arrow, Space, Page Up / Down, Home, and End navigation work.
- [ ] Touch navigation and the page counter work.
- [ ] Inline editing can be entered and exited without stealing keystrokes from editable text.
- [ ] `prefers-reduced-motion` reveals all evidence without delayed or missing content.
- [ ] Local assets use relative paths and load through HTTP.
- [ ] Browser console has no runtime errors.
- [ ] PDF export finds every `.slide`, reports the expected count, and produces the same number of pages.
- [ ] The exported PDF contains fonts, figures, citations, and final reveal states.
