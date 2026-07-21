---
name: write-debate-dialogue
description: Convert source text or text-extractable documents into a faithful two-person question-and-answer podcast with progressive disagreement, debate tension, and clear reasoning. Use when users ask to turn an article, report, essay, research note, PDF, DOCX, Markdown, or pasted text into dialogue, interview, Socratic exchange, opposing viewpoints, 针锋相对的对谈, 一问一答博客, 思辨对话, or 辩论式文章.
---

# Write Debate Dialogue

Turn the source into a real exchange of reasoning, not alternating paragraph summaries. Derive tension from the source's claims, evidence, assumptions, and limits. Never invent an opposing case merely to make the dialogue lively.

## Defaults

- Follow the source language; use Chinese for Chinese material.
- Produce a two-person podcast conversation.
- Use `medium` confrontation: direct disagreement and light irony without personal attacks.
- Write for an interested non-specialist unless the user names an audience.
- Choose role names from their reasoning functions or positions; avoid generic `甲/乙`.
- Use the shortest length that carries the source's complete argument.

Honor user-specified audience, role names, length, tone, and confrontation level when provided. Do not ask for preferences that can safely use these defaults.

## Workflow

### 1. Read and audit the complete source

Read all relevant text before drafting. For a document, use the appropriate document reader and preserve section, page, quotation, table, and citation context.

Stop and name the missing prerequisite when the source is empty, inaccessible, or too incomplete to support a real argument. Do not extrapolate from a title, fragments, failed OCR, or truncated tables.

Build a private source ledger:

- central question;
- explicit claims;
- evidence, figures, examples, and attributions supporting each claim;
- assumptions connecting evidence to conclusions;
- counterarguments already present;
- limitations, uncertainty, and unresolved contradictions;
- facts or passages that cannot be read reliably.

Do not include this ledger in the final output unless the user asks for it.

### 2. Find the honest disagreement

Identify where an informed reader could challenge:

- a definition;
- the strength or relevance of evidence;
- a causal leap;
- an unstated baseline;
- an assumption;
- a tradeoff;
- a generalization;
- an application boundary;
- an alternative explanation.

If the source is one-sided, challenge its evidence strength, assumptions, or boundary conditions. Do not fabricate contrary facts, motives, quotations, or authorities.

### 3. Assign two functional roles

Give each role a coherent reasoning job rather than a permanent moral label.

Use this default pairing when the source suggests no better roles:

- **推进者** — voices the reader's first reaction, common narrative, practical concern, or surface conclusion; asks concise questions and may revise their view.
- **拆解者** — tests evidence, numbers, mechanisms, assumptions, and limits; usually answers at greater length and must admit what the source cannot establish.

Allow roles to exchange attack and defense. Let a character concede, narrow, or update a claim when evidence warrants it. Never make one role deliberately stupid so the other can win.

### 4. Map 4–8 escalating beats

Reorder the material for reasoning rather than following source paragraphs mechanically. Prefer this progression when supported:

1. surface conclusion or common intuition;
2. first counterintuitive fact;
3. key evidence or mechanism;
4. strongest available objection;
5. hidden assumption or cost;
6. boundary or failure case;
7. higher-level decision framework;
8. unresolved question.

Skip unsupported beats. Give every beat a distinct function. Two adjacent beats must not repeat the same claim in different words.

### 5. Draft the conversation

Read [references/style-guide.md](references/style-guide.md) before drafting.

- Reach the dispute within the opening two turns.
- Use questions to escalate the reasoning, not merely request the next paragraph.
- Alternate short pressure-building turns with longer evidence-bearing turns.
- Keep each turn focused on one main move.
- Place numbers, quotations, and citations next to the claim they support.
- Use concrete analogies after dense reasoning when the source supports them.
- Prefer 6–10 turns for a short source and 8–16 turns for a substantial source.
- Split a very long dialogue into titled acts only when the argument has genuine phases.
- End with a real consensus, unresolved disagreement, decision boundary, or open question. Do not force a bland compromise.

Use confrontation levels as follows:

- `low`: Socratic questions, restrained corrections, no taunts;
- `medium`: direct rebuttals, pointed questions, light irony;
- `high`: shorter and sharper exchanges, stronger colloquial phrasing, unchanged factual and respect boundaries.

Intensity changes language, never evidence.

### 6. Protect source fidelity

Maintain these invariants:

- Trace every verifiable fact to the source.
- Preserve names, dates, figures, units, denominators, comparison baselines, and scopes.
- Preserve epistemic force: do not turn “可能”, “相关”, or “初步” into certainty or causation.
- Preserve the source's explicit conclusion even when a role challenges it.
- Keep quotations and citations attached to the relevant claim.
- Mark source conflicts or gaps as unresolved rather than silently deciding them.
- Phrase hypothetical questions as hypotheses, not established facts.
- Do not add web knowledge unless the user explicitly requests research; cite it separately if added.

### 7. Deliver in Podcast form

Use this structure unless the user requests another:

```markdown
# [A title built around the central tension]

> [Optional one-sentence setup]

**[Role name]**： [one-sentence reasoning function]

**[Role name]**： [one-sentence reasoning function]

---

**[Role name]：** ...

**[Role name]：** ...

...
```

Add a final prose note only when it clarifies the source boundary, unresolved evidence, or a domain-required disclaimer. Do not append a generic summary that repeats the dialogue.

### 8. Audit before delivery

Read [references/quality-checklist.md](references/quality-checklist.md). Check the draft against every blocking item and correct failures before delivering.

## Hard Boundaries

- Do not create video, audio, subtitles, storyboards, or visual assets.
- Do not reduce the task to paragraph-by-paragraph FAQ conversion.
- Do not invent facts, citations, quotations, motives, or a fake opposition.
- Do not use insults, identity attacks, or repetitive outrage as a substitute for reasoning.
- Do not hide unreadable source passages behind confident prose.
- Do not claim both sides are equally supported when the source evidence is asymmetric.
