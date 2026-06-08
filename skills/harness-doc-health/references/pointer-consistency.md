# Pointer Consistency

Top-level governance files each own a distinct responsibility.

- `PROGRESS.md`: cumulative execution summaries
- `NEXT_STEP.md`: one pointer to the active spec, plan, or checklist
- `MEMORY.md`: durable lessons, stable boundaries, recurring pitfalls

## Checks

- `NEXT_STEP.md` must contain one active pointer or be intentionally cleared when no follow-up task exists.
- `PROGRESS.md` should summarize the same active loop named by `NEXT_STEP.md` when work is still in flight.
- `MEMORY.md` should not become a second progress log.
