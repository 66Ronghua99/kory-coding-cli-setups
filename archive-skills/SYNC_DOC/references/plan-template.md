# .plan Design Template (Strict)

文件命名：`.plan/{YYYYMMDD}_{feature_name}.md`

## 固定章节顺序（必须一致）

1. `Problem Statement`
2. `Boundary & Ownership`
3. `Options & Tradeoffs`
4. `Migration Plan`
5. `Test Strategy`

## 每章最低要求

- `Problem Statement`: 当前痛点、约束、非目标。
- `Boundary & Ownership`: 模块边界、依赖方向、唯一真相源。
- `Options & Tradeoffs`: 至少 2 个可选方案与拒绝理由。
- `Migration Plan`: 增量步骤、兼容策略、回滚点。
- `Test Strategy`: 单元/集成/E2E 范围、验收标准、证据输出。

## 初始化骨架（可直接复制）

```markdown
# <Feature Name> Design

## Problem Statement
- Pain:
- Constraints:
- Non-goals:

## Boundary & Ownership
- Module boundary:
- Dependency direction:
- Source of truth:

## Options & Tradeoffs
- Option A:
  - Pros:
  - Cons:
  - Why rejected/selected:
- Option B:
  - Pros:
  - Cons:
  - Why rejected/selected:

## Migration Plan
- Step 1:
- Step 2:
- Compatibility strategy:
- Rollback point:

## Test Strategy
- Unit:
- Integration:
- E2E:
- Acceptance evidence:
```
