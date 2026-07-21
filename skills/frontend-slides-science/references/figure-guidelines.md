# Scientific Figure and Table Guidelines

## Fidelity

- Prefer the original figure or source data provided by the user.
- Never redraw a figure when doing so could change values, ordering, scale, uncertainty, or visual emphasis.
- When cropping, retain every axis, unit, legend, error definition, condition label, and caveat needed to interpret the result.
- Mark modified figures as `Adapted from …`; otherwise provide a concise source footer.
- Keep figure and table identifiers consistent with the source document.

## Statistical reporting

- State sample size and what the sample represents: subjects, observations, cells, runs, or another unit.
- Identify the uncertainty display: SD, SE, CI, posterior interval, range, or quantiles.
- Report effect direction and magnitude with uncertainty where available; do not make the p value the primary visual message.
- Preserve correction methods, model assumptions, and paired / unpaired structure when relevant.
- Do not imply causality from observational results.

## Visual encoding

- Keep each experimental group’s color stable across the deck.
- Never rely on red versus green alone. Add direct labels, shapes, line styles, or patterns.
- Use a common scale for direct comparisons. If panels require different scales, label the difference beside the axes.
- Prefer direct labels over distant legends when space permits.
- Preserve zero baselines for bars unless a justified exception is clearly marked.
- Use perceptually ordered palettes for continuous values and discrete palettes for categories.
- Avoid rainbow scales, pseudo-3D charts, pictograms, decorative gauges, and chart junk.

## Layout

- Use one main figure per slide, or two panels only when the audience must compare them directly.
- Enlarge a selected source panel rather than placing an unreadable full multi-panel figure on one page.
- Keep a short result statement near the evidence and a concise interpretation separate from the plot area.
- Figure annotations must not cover data marks or uncertainty bands.
- At 1920×1080 stage size, body text is at least 28 px and figure captions / citations are at least 20 px.
- Tables use aligned decimals, explicit units, restrained rules, and highlighted rows or columns only when they express the slide’s claim.

## Accessibility and theme checks

- Check contrast against the selected theme, especially imported figures in Dark Lecture.
- Do not automatically invert an image; inversion can change semantic colors and raster quality.
- Ensure labels remain understandable in grayscale.
- Use semantic HTML or accessible SVG labels when a figure is generated in HTML.

## Prohibitions

Do not invent missing plots, omit inconvenient controls, crop away limitations, convert qualitative evidence into fake quantitative charts, use tiny multi-panel figures, or decorate a slide with data-like marks that are not data.
