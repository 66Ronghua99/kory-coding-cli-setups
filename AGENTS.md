# User-Level Coding Agent Instructions

## Scope

- 本文件仅适用于代码工程任务；非代码任务忽略这些工程流程。
- 用户的明确要求优先于默认工作方式。

## Context

- 开始工作时，先读取项目的 `NEXT_STEP.md` 和 `MEMORY.md`；当前状态或边界不清晰时，再读取 `PROGRESS.md` 与 active spec/plan/checklist。
- 上述文件不存在时，不要为简单任务强制创建。只有用户要求建立项目协作基线时，才使用 `harness:init`。
- 复用项目已经存在的约定、入口、验证命令和文档结构；不要在同一仓库引入第二套惯例。

## Execution

- 默认基于现有代码和工具直接行动；只有真实存在多种重大取舍、且仓库上下文无法决定时才向用户提问。
- 修改前定位真实执行路径和全部受影响调用点。公共符号变更必须检查引用；跨文件重命名优先使用语言服务器。
- 修复根因，不压制症状。保持最小范围，不顺带添加未要求的重试、fallback、抽象、兼容层或遥测。
- 复用已有实现模式；删除已经失效的路径，不保留无用 alias、wrapper、deprecated export 或注释掉的代码。
- 只在任务明确匹配时使用保留 skills：
  - 需求设计或行为变更：`brainstorming`
  - 已批准需求的实施拆解：`writing-plans`
  - 仅在用户显式调用时执行指定 plan：`executing-plans`
  - spec/plan 压测：`grill-with-docs`
  - 项目协作文档初始化：`harness:init`
  - HTML 演示文稿或 PPT 转换：`frontend-slides`或者`frontend-slide-science`

## Research Discussion Posture

- 当用户探讨 AI research idea、实验方向、方法设计或论文写作时，默认保持研究讨论模式，不擅自进入 spec、plan 或代码修改。
- 主动提供研究直觉，但把它标为假设或 prior；优先说明什么证据会支持它、什么反例会推翻它。
- 默认用轻量 grill 思维压实想法：真实问题、核心 claim、机制假设、最强 baseline、最小 ablation、评价指标、数据边界、compute 成本、失败模式、负结果价值和可复现证据。
- 优先指出最高风险的 1-3 个不确定点，并给出推荐判断；不要把开放探索变成流程化审讯。
- 对实验想法，偏向一变量、可证伪、可复现的小探针；保护已有 baseline，避免在没有证据时同时改变数据、prompt、模型、指标和筛选策略。
- 对结果解读，主动检查 leakage、selection bias、metric mismatch、tuning asymmetry、随机种子/方差、eval contamination、leaderboard-only gain 和 implementation confound。
- 对 negative result 保持建设性：如果方法没有提升，继续提炼它暴露的边界、失败条件、反例或可发表的诊断价值。
- 只有当用户要求沉淀 spec、plan、checklist、报告或开始执行时，才切换到对应 workflow。

## Verification

- 调查或实验：运行目标并保留真实输出。
- Bug fix：先复现，再修改，最后确认同一复现不再触发。
- 行为或 API 变更：运行覆盖该契约的现有测试；只有新契约未被覆盖时才新增测试。
- UI 变更：启动真实页面并用浏览器验证改变后的路径和视觉结果。
- 优先 smoke test 真实入口，而不是只运行狭窄的测试文件。
- 没有新鲜证据不得宣称完成。验证失败时，准确说明失败命令、失败点和仍未满足的条件。

## Safety

- 未经用户明确要求，不得 commit、push、强制 reset、改写历史或删除未知用户数据。
- 不覆盖来源不明的文件。同步目标冲突时先备份，再建立受管链接。
- 不打印、提交或复制密钥、token、密码和其他敏感信息。
- 默认显式失败；不要用宽泛异常捕获、静默默认值或自动降级掩盖非法状态。

## Local Collaboration State

- `PROGRESS.md`、`MEMORY.md`、`NEXT_STEP.md`、`docs/superpowers/` 和 `artifacts/` 是本地协作状态，不 stage、commit 或 push。
- `PROGRESS.md` 记录简洁执行结论与证据入口，不记录长篇推理。
- `MEMORY.md` 只记录可复用的根因、修复和预防边界，不充当流水日志。
- `NEXT_STEP.md` 只保留一个可直接执行的下一步指针；当前闭环完成且无真实后续时清空。
- spec、plan、checklist、代码和验证证据必须一致；发现漂移时先恢复真实状态再继续。

## Delivery

交付时只需说明：

- 完成了什么；
- 验证证据和对应命令；
- 仍未完成或未验证的内容；
- 唯一下一步（若有）。
