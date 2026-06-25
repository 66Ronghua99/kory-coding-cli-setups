# User-Level Collaboration AGENTS

## 0. North Star
以下指南适用于所有**代码工程项目**。这个 user-level 文件的职责不是重复 Superpowers 或 Humanize 的全部细节，而是把项目协作收敛到少量必要文档，并强制以 spec、plan、checklist、Humanize 执行证据和新鲜验证证据作为执行真相。

> 核心原则：**Superman 路由 + Superpowers 设计计划 + Humanize 执行 + 轻量文档骨架 + 证据先于结论**

> !!非代码项目请忽略以下所有要求!!

## 1. Hard Rules

### 1.1 编码前的默认上下文
每次进入代码工程任务前，默认先读取：
```text
NEXT_STEP.md
MEMORY.md
```

按需读取：
```text
PROGRESS.md
当前 active spec / plan / checklist
```

- 若项目缺少根级 `AGENTS.md`，先补最小版本再继续。
- 若缺少 `PROGRESS.md`、`MEMORY.md`、`NEXT_STEP.md`，先补最小骨架再继续。
- `PROGRESS.md` 不是强制每次阅读文件；它是 agent 执行小结的累计记录，按需查看。
- 如果用户不确定当前或之前做到哪一步，优先通过 `NEXT_STEP.md`、spec/plan 时间顺序、checklist 完成情况，以及必要的代码审查来恢复状态，而不是依赖流水日志。

### 1.2 Superman 为默认宏观入口
- 每次非平凡代码工程任务默认先进入 `superman`。
- `superman` 的职责类似 user-level 的 `using-superpowers`：先读取必要上下文，再判断走轻量实现、Superpowers 设计计划、Humanize 执行，或仓库文档治理。
- `using-superpowers` 仍负责底层 skill discipline；只要存在匹配 skill，就必须走该 skill，不允许用临时流程替代。
- `Superpowers` 负责 brainstorm/spec/plan，`Humanize` 负责大 feature 的 RLCR 执行与 review gate，`Harness` 只保留初始化和文档健康治理。
- 常用路由如下：
  - 项目初始化或仓库 bootstrap：`harness:init`
  - 大 feature、复杂行为变化、跨模块工作流：`superman`
  - 新功能、行为变化、工作流变化：`brainstorming`
  - Bug、回归、测试失败、异常行为：`systematic-debugging`
  - 已批准 spec 或已冻结需求进入实施拆解：`writing-plans`
  - 已批准 plan 的大 feature 执行：`humanize-rlcr`
  - 小型、边界清楚、低风险任务：读取局部上下文后直接实现并验证
  - 任意 feature / bugfix 代码实现：优先保持测试先行；按任务风险决定是否需要完整 TDD 仪式
  - 仓库真相、指针漂移、spec/plan/evidence 脱节：`harness:doc-health`
  - 任务边界或交付前审查：`requesting-code-review`
  - 任何“完成 / 修复 / 通过”声明前：`verification-before-completion`
  - 分支或工作区收尾：`finishing-a-development-branch`

### 1.3 默认显式失败，避免过度回退
- 不要为了“看起来更稳”预设大量 fallback、兜底分支或吞异常逻辑。
- 如果某个前提不成立、依赖缺失、状态非法，优先直接报错，并保留足够的错误上下文让后续 agent 能快速定位。
- 只有在以下情况才添加 fallback / recovery path：
  - 已明确写入需求或兼容性契约
  - 用户体验上必须保底，且成本明显低于暴露错误
  - 该回退路径本身可测试、可观测、可维护
- 禁止用宽泛 `try/catch`、静默默认值、自动降级来掩盖真实问题。
- 允许失败早暴露，优先通过报错、日志、review 和 debugging 闭环迭代，而不是提前堆复杂异常处理。

### 1.4 文档职责保持清晰
- `AGENTS.md`：静态政策、协作边界、入口规则
- `PROGRESS.md`：agent 任务执行小结的累计记录，不是每回合必读入口
- `MEMORY.md`：可复用经验、稳定边界、易踩坑
- `NEXT_STEP.md`：唯一下一步指针，只引用 active spec / plan / checklist
- `docs/superpowers/specs/`：冻结后的设计真相
- `docs/superpowers/plans/`：当前闭环的执行计划与 checklist
- `artifacts/`：日志、截图、验收证据

一旦文档与实现脱节，先对齐文档，再继续推进。

### 1.5 AGENTS 采用稀疏层级，不做目录污染
- user-level `AGENTS.md` 只负责全局协作政策
- 项目根 `AGENTS.md` 负责该仓库的概览、入口、验证方式
- 模块级 `AGENTS.md` 仅在存在明确边界时添加
- 不要给 `utils/`、`types/`、`hooks/`、纯常量目录批量铺设 `AGENTS.md`
- 层级不清晰时，优先使用 `agents-hierarchy-sync`

## 2. Standard Superman Workflow
1. Route
- 默认读取 `NEXT_STEP.md -> MEMORY.md`
- 若当前状态不清晰，再看 `PROGRESS.md` 与 active spec / plan / checklist
- 加载 `superman`
- 由 `superman` 按任务规模、风险和 active 文档状态决定轻量路径、Superpowers 路径、Humanize 路径或 doc-health 路径

2. Freeze Scope
- 新功能、行为变化、流程变化先走 `brainstorming`
- 形成书面 spec，并获得批准后再进入计划阶段

3. Plan
- 使用 `writing-plans`
- 将执行计划与 checklist 写入项目声明的计划路径
- 一次只保持一个主闭环处于 Active

4. Execute
- 大 feature 或复杂计划默认使用 `humanize-rlcr`
- Humanize 生成的 round prompt、summary、review result、goal tracker 是执行层事实
- 小型低风险任务可直接实现，但仍必须保留足够的测试或 smoke 证据

5. Review And Verify
- 在任务边界或交付前使用 `requesting-code-review`
- 运行项目质量门禁
- 在任何完成声明前使用 `verification-before-completion`

6. Finish And Sync Back
- 使用 `finishing-a-development-branch` 完成分支/工作区收尾
- 回写 `PROGRESS.md`、`MEMORY.md`、`NEXT_STEP.md`、plan checklist、Humanize 证据路径与验证证据路径
- `NEXT_STEP.md` 永远只保留一个直接指针；如果当前任务已完成且没有新任务，就清空它
- goal 结束后默认补一次文件状态审查，确保 `PROGRESS.md`、`MEMORY.md`、`NEXT_STEP.md` 与 active spec / plan / checklist 一致

## 3. Context Loading Protocol
- L0：`NEXT_STEP.md -> MEMORY.md`
- L1：当前 Active spec + 当前 Active plan / checklist
- L2：`PROGRESS.md` + 必要的代码审查，仅在当前状态、完成度或任务边界不清晰时使用

触发 L1 / L2 的常见条件：
- 跨模块改造
- 公共契约变化
- 验收标准漂移
- 回归问题追根溯源
- 用户不确定之前做到哪
- 需要判断某条 plan 是否已经完成或过期

## 4. Project Context Governance
- 每个代码仓库都应有一个根级 `AGENTS.md`
- `harness:init` 只生成最小协作文档骨架和 `docs/superpowers/templates/`
- 不再把隐藏 manifest、额外索引文件或流水日志视为 user-level 初始化前提
- 优先少而精的高信号文档，而不是全目录铺文档

## 5. Quality Gate
交付前必须：
- 运行项目声明的验证命令
- 确认 active spec / plan / checklist 与当前交付边界一致
- 如果项目尚未声明门禁，至少执行最强可用的 `test`、`typecheck`、`build` 等价验证
- 若任一门禁失败，不得宣称完成，必须明确失败点和修复计划

## 6. Definition of Done
只有以下条件同时满足才算 Done：
- 当前 scope / plan step 已完成
- 应走的 `superman` / Superpowers / Humanize skill path 已实际执行
- 有新鲜的验证证据
- 审查意见已修复，或明确记录延期理由
- `PROGRESS.md`、`MEMORY.md`、`NEXT_STEP.md` 与 checklist 已同步
- goal 收尾文件状态审查没有留下未解释的漂移

## 7. Handoff Format
每次交付至少要说明：
- 这次完成了哪个闭环
- 证据在哪里
- 还有什么未完成
- 下一步 `P0` 动作是什么

## Quick Check
每次编码前：
```text
- 读取 NEXT_STEP.md
- 读取 MEMORY.md
- 如状态不清晰，再读取 PROGRESS.md
- 查看当前 active spec / plan / checklist
- 加载 superman
- 按路由进入对应 process skill
```

每次编码后：
```text
- 运行 review 与 verification
- 对齐文档与证据
- 更新 PROGRESS.md 为最新任务小结
- 更新 NEXT_STEP.md 为唯一下一步指针；若无下一步则清空
- 检查 MEMORY.md 没有混入过程流水
```
