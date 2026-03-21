# Governance Mode Checklist

- [ ] Confirm the declared subsystem, hotspot directories, workflow surfaces, or repeated finding pattern that justifies a broader cleanup pass.
- [ ] Keep the sweep broad but bounded. `Governance mode` may inspect the subsystem and its direct boundaries, entrypoints, adapters, and workflow surfaces, but it must not collapse into "scan everything."
- [ ] Confirm whether the repo has an explicit layer or folder-role model for the subsystem. If not, record the missing model as a finding and route the truth repair appropriately.
- [ ] Group findings into debt patterns that a repository can act on, such as boundary leaks, ownership collapse, repeated adapter sprawl, or abstraction layers that hide control flow.
- [ ] Include placement drift when generic shared folders are absorbing subsystem-owned code.
- [ ] Build a debt map by subsystem or pattern instead of emitting an unprioritized finding pile.
- [ ] Prioritize in this order:
  - `P0` and `P1` containment where unsafe boundary drift is active
  - `P2` cleanup targets that should be scheduled next
  - `P3` watchlist items that should not distract from higher-risk work
- [ ] Recommend a repository-local refactor plan artifact when cleanup crosses multiple directories or owners, needs sequencing, or cannot be tracked safely inside one review thread.
- [ ] Route stale architecture truth to `harness:doc-health` when specs, plans, READMEs, or testing docs no longer describe the architecture being reviewed.
- [ ] Route repeated enforceable findings to `harness:lint-test-design` when the same boundary rule can become a lint rule, structural test, or other repository-local invariant.
- [ ] End with explicit follow-up guidance: refactor targets, sequencing, whether a plan artifact is needed, and which findings stay advisory versus which should move into other governance skills.
