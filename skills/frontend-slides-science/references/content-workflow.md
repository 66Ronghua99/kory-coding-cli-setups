# Scientific Content Workflow

## Source inventory

Before outlining slides, list every input file and assign one role: primary manuscript, supplement, figure source, notes, or prior deck. Do not merge supplement content into the main argument without identifying it.

### Supported inputs

- Markdown / plain text: preserve heading hierarchy, tables, code blocks, image references, and explicit citations.
- Word `.docx`: extract headings, paragraphs, tables, figures, and captions with the host document reader. Report missing or flattened structure.
- PDF: extract text with page anchors plus figures, captions, and tables. An encrypted PDF, a scan without OCR, or a file whose text extraction is materially incomplete is a blocking source error.
- PPTX compatibility: run `python scripts/extract-pptx.py <input.pptx> <output-dir>` and inspect the extracted JSON and assets before conversion.

## Claim record

Create one internal record for each material claim:

```text
claim: concise statement
role: context | gap | hypothesis | method | result | interpretation | limitation | conclusion
source: file + page/section + figure/table identifier when present
evidence: quoted or faithfully compressed source content
status: verified | conflicting | missing
slide_use: proposed slide number or appendix
```

Rules:

- `verified` means the wording, number, unit, and direction are supported by the source.
- `conflicting` preserves every conflicting source location; the user resolves it.
- `missing` identifies information required for a proposed claim but absent from the source.
- An interpretation may connect verified observations, but it must be labeled as interpretation rather than source fact.
- Do not silently remove negative results, boundary conditions, failed experiments, or limitations.

## Scientific narrative

Reorganize the source into this sequence unless the user explicitly approves another logic:

1. Context — why the problem matters.
2. Gap — what knowledge or method is missing.
3. Question / Hypothesis — the precise claim being tested.
4. Approach — how the design distinguishes competing explanations.
5. Evidence — the result, effect size, uncertainty, and controls.
6. Interpretation — what the evidence supports and does not support.
7. Limitations — scope, bias, uncertainty, and unresolved questions.
8. Conclusion / Next Step — evidence-backed takeaways and one justified next step.

Do not create empty template sections. If the source does not contain a hypothesis or next step, omit it or mark it as missing for user input.

## Outline contract

Before generating HTML, present every planned slide with:

```text
number:
role:
conclusion_title:
evidence_or_figure:
source:
layout:
missing_inputs:
```

A result slide title states its finding, not “Results,” “Analysis,” or the name of a chart. Get user confirmation of the complete outline before generation.

## Density modes

- Conference talk: one claim per slide, one main figure, 2–4 supporting statements.
- Group meeting / progress report: include design choices, controls, ablations, failures, and unresolved decisions.
- Reading-first report: self-contained explanations and citations, with dense material split across additional slides rather than reduced typography.

## Failure policy

Stop and report the exact source problem when:

- a PDF is encrypted or has not been OCRed;
- document extraction omits material tables or figures;
- a key number has inconsistent values or units;
- a figure cannot be associated with a caption or source;
- a required method or experimental condition is absent.

Do not replace missing content with generic prose, a fabricated diagram, or an inferred statistic.
