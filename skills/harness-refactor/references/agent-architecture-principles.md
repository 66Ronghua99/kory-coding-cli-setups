# Agent Architecture Principles

These principles define what `harness:refactor` is evaluating when it reviews architecture drift.

## 1. Agent Legibility First

Prefer structures that future coding agents can locate, parse, and modify safely without hidden chat context. If the repository shape, folder roles, ownership split, or control flow is hard to reconstruct from files alone, legibility has already started to drift.

## 2. Workflow Is Architecture

In agent systems, architecture is not only packages and layering. It also includes tools, knowledge access, handoffs, traces, and evaluation loops. When those workflow surfaces blur together, the repository may stay green while becoming harder to reason about or change.

## 3. Parse External Shapes At Boundaries

Tool outputs, retrieved context, runtime inputs, and other external shapes should be parsed and validated at the boundary. Core logic should not guess or reinterpret those shapes deep inside the workflow.

## 4. Prefer Explicit, Shallow Abstractions

Prefer explicit, shallow abstractions that are easy to inspect in-repo. Avoid clever indirection, deep wrapper stacks, or helper layers that make ownership and data flow harder for future agents to follow.

## 5. Folder Placement Is Part Of The Contract

Directory placement is not cosmetic when it communicates file role. If a file's location no longer matches its responsibility, that is architecture drift even when behavior stays green.

## 6. Small Continuous Cleanup Over Heroic Rewrites

Default to small, reviewable cleanup that steadily improves boundaries and readability. Use broader cleanup only when the repository explicitly chooses `governance mode` because the drift is already beyond what bounded review comments can unwind.
