# MEMORY Reference Template (Strict)

用于沉淀“可复用经验与约束”，禁止写阶段进度。

## 固定章节顺序（必须一致）

1. `Doc Ownership`
2. `Known Pitfalls`
3. `Migrated Experience`
4. `Environment Requirements`
5. `Working Conventions`

## 必填规则

- `Known Pitfalls`：每条建议使用统一格式：
  - `<主题> | Symptom: ... | Root Cause: ... | Fix: ... | Prevention: ...`
- `Migrated Experience`：只保留已验证有效的做法。
- `Environment Requirements`：列出运行前置约束（版本、端点、凭证、依赖）。
- `Working Conventions`：列执行顺序、关键工件、最小排障步骤。

## 禁止项

- 禁止写里程碑状态、TODO、DONE（应写入 `PROGRESS.md`）。
- 禁止写不可操作的泛化建议（例如“多测试”“注意稳定性”）。

## 初始化骨架（可直接复制）

```markdown
# MEMORY

## Doc Ownership
- `PROGRESS.md`: 里程碑状态、TODO/DONE。
- `MEMORY.md`: 经验、根因、修复、预防。
- `NEXT_STEP.md`: 单条下一步执行指针。

## Known Pitfalls
- <主题> | Symptom: <现象> | Root Cause: <根因> | Fix: <修复> | Prevention: <预防>

## Migrated Experience
- <主题> | <已验证有效做法>

## Environment Requirements
- <版本/端点/凭证/依赖前置条件>

## Working Conventions
- <固定执行顺序>
- <关键工件清单>
- <最小排障路径>
```
