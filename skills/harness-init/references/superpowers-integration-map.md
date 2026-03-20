# Superpowers Integration Map

Harness and Superpowers have different jobs.

## Superpowers Owns Workflow

- `using-superpowers`
- `brainstorming`
- `writing-plans`
- `executing-plans` or `subagent-driven-development`
- `test-driven-development`
- `requesting-code-review`
- `verification-before-completion`
- `finishing-a-development-branch`

## Harness Owns Governance Standards

- `harness:init`: bootstrap the repository baseline
- `harness:doc-health`: define repository truth and pointer consistency standards
- `harness:lint-test-design`: define lint/test invariants and rollout standards

The agent should read Harness to know what "correct" means, then use Superpowers to perform the work.
