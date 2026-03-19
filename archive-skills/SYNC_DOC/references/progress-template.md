# PROGRESS Reference Template (Strict)

用于记录“项目当前状态与下一步优先级”，禁止写成长篇设计推理。

## 固定章节顺序（必须一致）

1. `Doc Ownership`
2. `Current Milestone`
3. `Ultimate Goal`
4. `Reference List (Progressive Loading)`
5. `TODO`
6. `DONE`

## 必填规则

- `Doc Ownership`：明确三份核心文档职责，且互不重叠。
- `Current Milestone`：至少一条里程碑状态，格式建议：
  - `M{n} ({Done|In Progress|Blocked})`
- `Ultimate Goal`：1-3 句，写长期目标，不写当前迭代细节。
- `Reference List`：必须包含 `L0/L1/L2` 三层加载入口。
- `TODO`：
  - 必须包含且仅包含一条 `P0-NEXT`
  - 其他任务使用 `P1`、`P2`
- `DONE`：每条结论尽量附证据，格式建议：
  - `<结论> | Evidence: <命令/工件/文件路径>`

## 禁止项

- 禁止在 `PROGRESS.md` 记录排障长文、复盘细节、经验总结（应写入 `MEMORY.md`）。
- 禁止出现“看起来完成”“基本可用”等不可验证措辞。
- 禁止 `TODO` 中出现多个 `P0-NEXT`。

## 初始化骨架（可直接复制）

```markdown
# PROGRESS

## Doc Ownership
- `PROGRESS.md`: 里程碑状态、TODO/DONE、渐进加载入口。
- `MEMORY.md`: 经验、根因、修复、预防。
- `NEXT_STEP.md`: 单条下一步执行指针。

## Current Milestone
- `M1 (In Progress)`: <当前阶段目标>

## Ultimate Goal
- <项目长期目标>

## Reference List (Progressive Loading)
- L0: `PROGRESS.md` -> `NEXT_STEP.md` -> `MEMORY.md`
- L1: <当前阶段 plan/checklist 路径>
- L2: <历史文档或归档路径>

## TODO
- `P0-NEXT` <唯一下一条必须推进任务>
- `P1` <重要但不阻塞>
- `P2` <可延后优化>

## DONE
- <里程碑结论> | Evidence: <工件/命令/路径>
```
