---
name: harness-doc-health
description: >
  使用 when 需要对仓库级文档进行健康检查：bootstrap 完整性、spec/plan/evidence
  图谱关系、以及 spec -> plan -> evidence 的 stale truth 漂移。适用于编码前检查、文档回归扫描、
  CI 阻断，以及 agent 交付前验证。
---

# harness-doc-health

仓库级文档健康检查工具。当前只维护三条正式 phase entrypoint：

- `--phase bootstrap`
- `--phase graph`
- `--phase drift`

它们共同假设：仓库内文档是系统真源，检查器只读取显式结构，不做 prose 猜测。

## 快速使用

```bash
# Phase 1: Bootstrap Health
node ~/.coding-cli/skills/harness-doc-health/scripts/doc-health.js /path/to/repo --phase bootstrap

# Phase 2: Document Graph Health
node ~/.coding-cli/skills/harness-doc-health/scripts/doc-health.js /path/to/repo --phase graph

# Phase 3: Execution Drift Health
node ~/.coding-cli/skills/harness-doc-health/scripts/doc-health.js /path/to/repo --phase drift

# 回归测试
cd ~/.coding-cli/skills/harness-doc-health && npm test
```

## Phase 1: Bootstrap Health

检查仓库是否已经按 Harness bootstrap 成功。

当前会检查：

- `.harness/bootstrap.toml` 是否存在且字段完整
- 根级治理文件是否齐全
- `docs/superpowers/templates/` 是否完整
- 模板必需 heading 是否存在
- `AGENTS.md` / `AGENT_INDEX.md` 是否包含关键路由标记

Phase 1 不做：

- 跨文档图谱推理
- stale truth 漂移检测
- 代码结构 lint

## Phase 2: Document Graph Health

检查 metadata-bearing 文档之间的显式关系是否成立。

当前最小模型：

- 文档使用 YAML front matter
- 只覆盖 `spec`、`plan`、`evidence`
- 状态枚举：`draft | active | deprecated | superseded | archived`
- 关系字段：`implements`、`verified_by`、`supersedes`、`related`
- 所有关系字段使用仓库相对路径

Phase 2 不做：

- prose 语义理解
- contract drift
- 代码层架构边界检查

## Phase 3: Execution Drift Health

检查 `spec -> plan -> evidence` 之间的 stale truth，即图谱仍然合法，但执行或验证已经过期。

当前模型：

- `spec` 保持意图真相
- `plan` 通过 `## Execution Truth` 保存执行真相
- `evidence` 通过 `## Verified Claims` 保存验证真相
- freshness 通过短 SHA-256 hash 检查

Phase 3 v0 只支持两个 source section families：

- `Frozen Contracts`
- `Acceptance`

这些 source section 必须带显式 `drift_anchor`：

```md
## Frozen Contracts
<!-- drift_anchor: frozen_contracts -->

## Acceptance
<!-- drift_anchor: acceptance -->
```

`plan` 需要的 block 形状：

```yaml
schema: harness-execution-truth.v1
claims:
  - claim_id: plan.example.frozen-contracts
    source_spec: docs/superpowers/specs/example-spec.md
    source_anchor: frozen_contracts
    source_hash: 0123456789ab
```

`evidence` 需要的 block 形状：

```yaml
schema: harness-verified-claims.v1
verified_claims:
  - claim_id: evidence.example.frozen-contracts
    plan_path: docs/superpowers/plans/example-plan.md
    plan_claim_id: plan.example.frozen-contracts
    plan_hash: 0123456789ab
    artifacts:
      - artifacts/example/evidence.md
```

Phase 3 不做：

- provider 直连、分层越界等代码级规则
- 任意 prose 语义理解
- 替代 TDD、集成测试或 E2E

## 输出解释

输出分三层：

- `ERROR`
  - 必须修复；命令会返回非零退出码
- `WARNING`
  - 当前不阻断，但代表 rollout gap、缺少 freshness 维护或需要补齐结构
- `INFO`
  - 仅提示

CLI 输出括号中的第一段永远是源文档；后续键帮助 agent 快速定位：

- Phase 1: `key` / `heading` / `marker`
- Phase 2: `field` / `target`
- Phase 3: `claim_id` / `plan_claim_id` / `anchor` / `target`

## 边界

- 需要 lint、pytest、结构测试解决的问题，不要塞进 `harness-doc-health`
- 需要 prose 理解的问题，不要伪装成机器可检规则
- 只有显式结构化的仓库真相，才应该进入 phase checker
