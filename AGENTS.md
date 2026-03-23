# User-Level Collaboration AGENTS

## 0. North Star
以下指南适用于所有**代码工程项目**。这个 user-level 文件的职责不是重复 Superpowers 的全部细节，而是强制项目工作走 `superpowers skill set` 的标准闭环，并用少量本地文档把项目状态、路由与验证证据固定下来。

> 核心原则：**Superpowers First + 分形文档 + 证据先于结论**

> !!非代码项目请忽略以下所有要求!!

## 1. Hard Rules

### 1.1 编码前强制读取上下文
每次进入代码工程任务前，先读取：
```text
PROGRESS.md
NEXT_STEP.md
MEMORY.md
AGENT_INDEX.md（项目根优先，兜底为 /Users/cory/.coding-cli/AGENT_INDEX.md）
.harness/bootstrap.toml（若存在）
```

- 若项目缺少根级 `AGENTS.md`，先补最小版本再继续。
- 若缺少 `PROGRESS.md`、`MEMORY.md`、`NEXT_STEP.md`，先补最小骨架再继续。
- 在路由和当前状态不清晰前，不允许直接编码。

### 1.2 Superpowers Skill Set 为默认执行入口
- 每次代码工程对话默认先进入 `using-superpowers`。
- 只要存在匹配 skill，就必须走该 skill，不允许用临时流程替代。
- `Superpowers` 负责流程执行，`Harness` 负责仓库治理标准、文档真相、lint/test invariant 与 architecture drift 治理。
- 常用路由如下：
  - 项目初始化或仓库 bootstrap：`harness:init`
  - 新功能、行为变化、工作流变化：`brainstorming`
  - Bug、回归、测试失败、异常行为：`systematic-debugging`
  - 已批准 spec 或已冻结需求进入实施拆解：`writing-plans`
  - 开始实施且需要隔离工作区：`using-git-worktrees`
  - 在支持 subagent 的环境执行计划：`subagent-driven-development`
  - 不走 subagent 模式但已有书面计划：`executing-plans`
  - 任意 feature / bugfix 代码实现：`test-driven-development`
  - 仓库真相、指针漂移、spec/plan/evidence 脱节：`harness:doc-health`
  - lint/test invariant、结构硬约束、可机械化复发问题：`harness:lint-test-design`
  - 架构漂移、边界坍塌、主动式重构治理：`harness:refactor`
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

### 1.4 文档与实现强制同构
- `AGENTS.md`：静态政策、目录入口、边界说明
- `AGENT_INDEX.md`：任务路由与 agent / skill 选择
- `PROGRESS.md`：当前里程碑、TODO、DONE、参考入口
- `MEMORY.md`：可复用经验、易踩坑、稳定边界
- `NEXT_STEP.md`：唯一下一步执行指针
- `.harness/bootstrap.toml`：仓库 bootstrap 与治理模型的机器可读 source of truth（若存在）
- `.plan/`：当前闭环的执行计划与 checklist
- 项目声明的 spec 路径：设计文档，默认 `docs/superpowers/specs/`
- `artifacts/`：日志、截图、验收证据

一旦文档与实现脱节，先对齐文档，再继续推进。

### 1.5 AGENTS 采用稀疏层级，不做目录污染
- user-level `AGENTS.md` 只负责全局协作政策
- 项目根 `AGENTS.md` 负责该仓库的概览、入口、验证方式
- 模块级 `AGENTS.md` 仅在存在明确边界时添加
- 不要给 `utils/`、`types/`、`hooks/`、纯常量目录批量铺设 `AGENTS.md`
- 层级不清晰时，优先使用 `agents-hierarchy-sync`

## 2. Standard Superpowers Workflow
1. Route
- 读取 `PROGRESS.md -> NEXT_STEP.md -> MEMORY.md -> AGENT_INDEX.md -> .harness/bootstrap.toml（若存在）`
- 加载 `using-superpowers`
- 由项目 `AGENT_INDEX.md` 决定当前任务应走的 agent / skill

2. Freeze Scope
- 新功能、行为变化、流程变化先走 `brainstorming`
- 形成书面 spec，并获得批准后再进入计划阶段

3. Plan
- 使用 `writing-plans`
- 将执行计划与 checklist 写入项目声明的计划路径
- 一次只保持一个主闭环处于 Active

4. Execute
- 实施开始前按需使用 `using-git-worktrees`
- 优先 `subagent-driven-development`，否则使用 `executing-plans`
- 任意 feature / bugfix 代码都遵守 `test-driven-development`

5. Review And Verify
- 在任务边界或交付前使用 `requesting-code-review`
- 运行项目质量门禁
- 在任何完成声明前使用 `verification-before-completion`

6. Finish And Sync Back
- 使用 `finishing-a-development-branch` 完成分支/工作区收尾
- 回写 `PROGRESS.md`、`MEMORY.md`、`NEXT_STEP.md`、plan checklist 与证据路径
- `NEXT_STEP.md` 永远只保留一条直接可执行指针

## 3. Context Loading Protocol
- L0：`PROGRESS.md -> NEXT_STEP.md -> MEMORY.md -> AGENT_INDEX.md -> .harness/bootstrap.toml（若存在）`
- L1：当前 Active spec + 当前 Active plan / checklist
- L2：历史 specs / plans，仅用于回归、审计、验收口径争议

触发 L1 / L2 的常见条件：
- 跨模块改造
- 公共契约变化
- 验收标准漂移
- 回归问题追根溯源

## 4. Project Context Governance
- 每个代码仓库都应有一个根级 `AGENTS.md`
- 模块级 `AGENTS.md` 仅当目录至少满足以下两项时才建议添加：
  - 独立职责边界
  - 独立运行入口
  - 高频变更
  - 容易遗漏的本地坑点
  - 高跨模块协调成本
- 优先少而精的高信号文档，而不是全目录铺文档

## 5. Quality Gate
交付前必须：
- 运行项目声明的验证命令
- 若仓库已声明 Harness 治理模型，先确认文档真相、lint/test invariant 文档与当前交付边界一致
- 如果项目尚未声明门禁，至少执行最强可用的 `test`、`typecheck`、`build` 等价验证
- 若任一门禁失败，不得宣称完成，必须明确失败点和修复计划

## 6. Definition of Done
只有以下条件同时满足才算 Done：
- 当前 scope / plan step 已完成
- 应走的 superpowers skill path 已实际执行
- 有新鲜的验证证据
- 审查意见已修复，或明确记录延期理由
- `PROGRESS.md`、`MEMORY.md`、`NEXT_STEP.md` 与 checklist 已同步

## 7. Handoff Format
每次交付至少要说明：
- 这次完成了哪个闭环
- 证据在哪里
- 还有什么未完成
- 下一步 `P0` 动作是什么

## Quick Check
每次编码前：
```text
- 读取 PROGRESS.md
- 读取 NEXT_STEP.md
- 读取 MEMORY.md
- 读取 AGENT_INDEX.md（项目根优先，共享兜底其次）
- 若存在则读取 .harness/bootstrap.toml
- 加载 using-superpowers
- 按路由进入对应 process skill
```

每次编码后：
```text
- 运行 review 与 verification
- 对齐文档与证据
- 更新 NEXT_STEP.md 为唯一下一步指针
```
