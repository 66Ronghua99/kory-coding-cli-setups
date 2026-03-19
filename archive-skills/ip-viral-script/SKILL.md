---
name: ip-viral-script
description: Compatibility wrapper for the content-creator-collab skill's to-hot-script phase. Use when the user asks to模仿/复刻 Don't Be Silent、优化开头钩子、把选题转成可直接口播脚本。
---

# Compatibility Wrapper

This skill is retained for backward compatibility.

Preferred path: use `$content-creator-collab` with phase `to-hot-script`.

## Behavior

When invoked, follow the same contract as `content-creator-collab` phase `to-hot-script`:
- Read `references/style-patterns.md`
- Read `references/opening-samples.md`
- Collect or infer:
  - `topic`
  - `target_audience`
  - `core_claim`
  - `proof_points`
  - `cta_goal`
- Output exactly:
  - `Hook Candidates (3)`
  - `Final Opening (0:00-0:20)`
  - `Main Script (0:20-1:30)`
  - `Closing + CTA (last 10-15s)`
  - `Delivery Notes`

## Migration Prompt

```text
使用 $content-creator-collab，阶段 to-hot-script。
把这个已定选题改写成高传播口播脚本：
- 选题：{{topic}}
- 目标人群：{{target_audience}}
- 核心观点：{{core_claim}}
- 证据：{{proof_points}}
- 目标动作：{{cta_goal}}
```
