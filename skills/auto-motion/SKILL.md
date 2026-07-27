---
name: auto-motion
description: End-to-end runbook that takes a transcription.srt through deterministic scene planning, parallel OMP-native scene builds, transactional assembly, and human review, producing a published final.mp4.
---

# auto-motion — end-to-end runbook

Read this entire skill before taking any action. Every phase is mandatory unless gated.
This skill is a user-level OMP skill (installed at `~/.omp/agent/skills/auto-motion/`). Before the first use in a directory, run Phase -1 to inject the project assets. Once initialized, the directory contains:

- `scripts/` — deterministic Node.js commands
- `.omp/agents/` — three task subagents (`asset-scout`, `scene-builder`, `preference-curator`)
- `.omp/skills/` — skill references
- `schemas/` — JSON Schema contracts
- `templates/scene/` — HyperFrames scaffold


## Phase -1: Initialize (first time only)

If `.omp/skills/hyperframes/` does not exist in this directory, the project assets have not been set up. Run the init script:

```bash
bash "$(dirname "$(omp skill path auto-motion 2>/dev/null || echo "$HOME/.omp/skills/auto-motion")")/init.sh" .
```

This copies skills, agents, scripts, schemas, templates, and config into the current directory and installs dependencies. Skip this phase if `.omp/skills/hyperframes/` already exists.

## Phase 0: Preflight

Run deterministic preflight before any scene work:

```bash
node scripts/preflight.mjs
```

Preflight checks Node 22+, FFmpeg/FFprobe, HyperFrames 0.7.72 doctor, writable `runs/`, API keys, and model catalog. It exits non-zero on any required failure. Prompts with missing `MINIMAX_API_KEY` receive a warning that disables generated-image sourcing.

## Phase 1: Model Smoke

Before building any scene, dispatch one `scene-builder` in `model-smoke` mode to confirm the model responds:

1. Create a smoke packet directory below `.auto-motion-tmp/model-smoke-<uuid>/`.
2. Write a sentinel text file inside it.
3. Dispatch one task agent with `agent=scene-builder` and mode `model-smoke`:

```
# Target: scene-builder agent, mode model-smoke
# Change: Read sentinel, write copy, run sha256sum, yield result
# Acceptance: status=passed with matching checksum
```

4. Remove the smoke packet after recording evidence. Stop on failure.

## Phase 2: Create or Resume a Run

### New run

```bash
node scripts/create-run.mjs --input transcription.srt
```

Read the frozen transcript and preferences. Apply current user instructions above the frozen preferences when authoring plans.

### Existing run

```bash
node scripts/preflight.mjs
node scripts/plan-resume.mjs --run runs/<run-id>
node scripts/prepare-resume.mjs --run runs/<run-id>
```

Reuse every scene marked for reuse. Rebuild only invalidated scenes. Input hash changes = create a new run.

## Phase 3: Visual Bible

Read `schemas/visual-bible.schema.json`. Write one `runs/<run-id>/visual-bible.json` that conforms to the schema. The `full_story_summary` must be exactly one sentence (max 200 characters). Use the frozen project/global preferences as defaults; the user's current instructions override.

## Phase 4: Scene Plans

Partition every cue exactly once into contiguous scene plans. Write each plan at `runs/<run-id>/scenes/<scene-id>/scene-plan.json`. Each plan has exactly one blueprint (from `skill://hyperframes-motion/catalog.json`) and at most one rule.

Run planning validation to collect declared asset IDs:

```bash
node scripts/validate-scene-plans.mjs --run runs/<run-id> --allow-unresolved-assets
```

## Phase 5: Asset Resolution

If any plan declares assets, dispatch exactly one `asset-scout` agent and freeze `assets/index.json`. Then:

```bash
node scripts/validate-scene-plans.mjs --run runs/<run-id>
```

If no assets are declared, run resolved validation immediately.

## Phase 6: Prepare Scenes

```bash
node scripts/prepare-run.mjs --run runs/<run-id> <scene-id-1>,<scene-id-2>,...
```

Read the validated manifest summary. Every scene now has a compiled `scene-context.md` and an initial `status.json`.

## Phase 7: Dispatch Scene Builders (ONE BATCH)

Dispatch every planned scene in ONE task batch using `agent=scene-builder`. Never serialize — all go in one `tasks[]` array. Each task names only the run ID and scene ID.

```
# Target: scene-builder in mode scene, run=<id>, scene=<scene-id>
# Change: Read context via load-scene-context.sh, build the HyperFrames composition, render to MP4
# Acceptance: Self-report status.json, yield structured output with mode=scene
```

## Phase 8: Record Results

For each completed builder result, run:

```bash
node scripts/record-scene-result.mjs --run runs/<run-id> --result-file <result-json-path>
```

The recorder runs its own fresh deterministic validation and is the sole authority for manifest status.

### Repairable scenes (technical errors)

Resume the same builder through `hub send` if available. If unavailable, dispatch a fresh `scene-builder` with the same model selector, packet/context hashes, and a machine repair brief. Stop after 2 repair attempts per scene.

### Provider failures

Pause immediately on provider failures. Do not change the model or attempt fallback. The run status becomes `paused`.

## Phase 9: Assemble

If every scene is `passed`:

```bash
node scripts/assemble-video.mjs --run runs/<run-id>
```

Otherwise, report failed scenes and the exact resume command.

## Phase 10: Review Loop

Present `final.mp4` and keep the review conversation open.

- Use `node scripts/locate-feedback.mjs` for timecode, scene ID, or subtitle queries.
- For natural-language feedback, inspect candidate cue/goal facts and ask only once if ambiguous.
- Apply scope rules: local changes (one scene), transition (adjacent scenes), or storyboarding (contiguous interval).
- For accepted revisions:
  ```bash
  node scripts/prepare-revision.mjs --run runs/<run-id> <scene-ids> --feedback-file feedback.md
  ```
  Then recompile/rebuild/reassemble.

## Phase 11: Preference Update

After explicit user acceptance of revision feedback:

1. Write `runs/<run-id>/accepted-feedback.json` with `accepted: true`.
2. Dispatch exactly one `preference-curator` agent.
3. Run:
   ```bash
   node scripts/apply-preference-update.mjs --run runs/<run-id> --update runs/<run-id>/preference-update.json
   ```
4. Display the diff output showing `global_changes`, `project_changes`, and `run_only`.

## Constraints

- Never dispatch one agent then wait — always batch all independent builders.
- Never use nested tasks inside agent definitions.
- Never edit outside each scene's directory from within a builder.
- Never edit the run manifest directly from a builder.
- Never claim visual quality from deterministic checks.
- Animations must be seek-deterministic: no `Date.now()`, runtime randomness, infinite repeat, CDN sources.
