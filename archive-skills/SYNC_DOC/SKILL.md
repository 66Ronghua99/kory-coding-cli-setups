---
name: syncdoc
description: 以代码为基准，整理过时文档并同步项目进度状态；在文档缺失或职责不清时，按标准模板初始化 PROGRESS/MEMORY/NEXT_STEP/.plan。
---

# SyncDoc: 项目进度文档同步与初始化（强化版）

## Goal

在不改变真实业务代码行为的前提下，稳定完成两件事：
- 用统一、可验证、可复现的结构维护 `PROGRESS.md`、`MEMORY.md`、`NEXT_STEP.md`
- 将 `.plan/` 文档夹规范化，保证设计文档与执行清单同构

## Hard Constraints (Non-Negotiable)

1. **事实来源约束**：所有“已完成”结论必须有代码或工件证据。
2. **职责边界约束**：
- `PROGRESS.md` 只写里程碑状态、TODO/DONE、渐进加载入口。
- `MEMORY.md` 只写可复用经验（根因/修复/预防）、环境约束、执行约定。
- `NEXT_STEP.md` 永远只保留一条可立即执行指针。
3. **同构约束**：三份核心文档标题顺序必须与模板一致，不得自定义重排。
4. **单指针约束**：`PROGRESS.md` 的 `P0-NEXT` 与 `NEXT_STEP.md` 必须语义一致。
5. **计划文档约束**：Design Path 必须使用 `.plan` 命名规范与模板骨架。

## Step 0: 模板初始化/重整

触发条件（任一满足即执行初始化）：
- `PROGRESS.md` / `MEMORY.md` / `NEXT_STEP.md` 任一缺失
- 三份文档职责混写
- `.plan/` 缺失统一命名与模板结构

必须加载以下模板：
1. `references/progress-template.md`
2. `references/memory-template.md`
3. `references/next-step-template.md`
4. `references/plan-template.md`
5. `references/checklist-template.md`

初始化规则：
- 先按模板建“空骨架”，再用项目事实填充。
- 未确认的事实写为 `TBD`，不得臆测。
- 若已有内容可复用，迁移到正确文档而不是直接删除。

## Step 1: 读取上下文（固定顺序）

1. `PROGRESS.md`
2. `NEXT_STEP.md`
3. `MEMORY.md`
4. `.plan/` 当前活跃设计文档与 checklist
5. 项目目录结构与关键实现文件

若核心文档缺失：回到 Step 0 初始化后继续。

## Step 2: 证据核对（以代码/工件为准）

对每条 DONE/里程碑结论做最小证据核对：
- 结构证据：目录/文件是否存在
- 行为证据：入口是否已接线到可执行路径
- 质量证据：是否有测试、构建或最小运行工件
- 漂移证据：是否存在 `TODO` / `not implemented` / 旧阶段命名

判定原则：
- “文档说完成”不算完成。
- “代码可调用 + 工件可核验”才算完成。

## Step 3: 同步与归档

### 3.1 同步 `PROGRESS.md`
- 按模板固定顺序保留章节。
- `TODO` 里必须且只能有一条 `P0-NEXT`。
- `DONE` 每条尽量附 `Evidence`（命令、工件、文件路径）。

### 3.2 同步 `MEMORY.md`
- 每条经验必须可复用，推荐 `Symptom | Root Cause | Fix | Prevention`。
- 移除阶段状态描述（迁回 `PROGRESS.md`）。

### 3.3 同步 `NEXT_STEP.md`
- 覆盖为单条指针，不追加历史。
- 必须包含：阶段名 + 动作 + 验收证据 + 输出物。

### 3.4 规范 `.plan/`
- 设计文档命名：`.plan/{YYYYMMDD}_{feature_name}.md`
- 清单命名：`.plan/checklist_{feature_name}.md`
- 若存在旧命名/过时文档：归档并在文首加归档说明。

归档说明模板：
```markdown
> [!NOTE]
> **归档文档** | 归档日期：YYYY-MM-DD
> 本文档作为历史参考保留，不再主动维护。
```

## Step 4: 自检清单（执行后必须通过）

- [ ] `PROGRESS.md` 是否包含且仅包含模板定义章节（顺序一致）
- [ ] `TODO` 是否只有一条 `P0-NEXT`
- [ ] `NEXT_STEP.md` 是否只有一条动作指针（单段）
- [ ] `P0-NEXT` 与 `NEXT_STEP` 是否语义对齐
- [ ] `MEMORY.md` 是否无阶段状态叙述
- [ ] `.plan` 是否符合命名规范并含设计 + checklist 成对文件
- [ ] 所有“完成”结论是否可追溯到证据

## Output Contract

每次执行后必须输出以下结构：
1. `Sync Summary`
2. `Evidence`
3. `Doc Changes`
4. `Plan Folder Changes`
5. `Validation Result`（逐条列出 Step 4 自检结论）
6. `Next Pointer`（最终写入 `NEXT_STEP.md` 的完整句子）

## Progressive Loading

- L0（默认）: `PROGRESS.md` -> `NEXT_STEP.md` -> `MEMORY.md`
- L1（当前阶段）: 当前活跃 `.plan/{date}_{feature}.md` + `checklist_{feature}.md`
- L2（历史追溯）: 仅在回归/争议时加载其他 `.plan/*.md`

## Appendix

若项目为全新初始化且需求未冻结，先调用 `pm-progress-requirement-discovery` 明确：
- Problem / Scope / Non-goals / Acceptance Criteria
再回到本技能执行文档初始化。

## Cross-Skill Orchestration

`syncdoc` is both entry guard and closing guard in the PM workflow chain:

1. Entry Guard
- Run before `pm-progress-requirement-discovery` when docs are missing/misaligned.
- Ensure `PROGRESS/MEMORY/NEXT_STEP/.plan` structure is valid.

2. Requirement-to-Execution Bridge
- After `pm-progress` + `drive-pm-closed-loop`, sync their outputs back into core docs.
- Required alignment:
  - `PROGRESS.md` contains exactly one `P0-NEXT`
  - `NEXT_STEP.md` single sentence semantically equals `P0-NEXT`
  - `.plan` contains requirement/design/checklist artifacts with valid naming

3. Closure Guard
- Do not mark stage complete until documentation and evidence are isomorphic:
  - Core docs updated
  - `.plan` active artifacts updated
  - Evidence paths traceable
