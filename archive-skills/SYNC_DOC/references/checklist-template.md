# .plan Checklist Template (Strict)

文件命名：`.plan/checklist_{feature_name}.md`

## 规则

- 状态仅允许 `[ ]` 或 `[x]`
- 每项必须可验证
- 至少包含：实现项、证据项、质量门禁项、文档同步项

## 初始化骨架（可直接复制）

```markdown
# Checklist: <feature_name>

## Implementation
- [ ] 关键实现 A 完成并可运行
- [ ] 关键实现 B 完成并可运行

## Evidence
- [ ] 产出工件/日志可追溯（列出路径）
- [ ] 验收证据与需求 AC 一一对应

## Quality Gates
- [ ] <项目质量门禁命令 1> 通过
- [ ] <项目质量门禁命令 2> 通过

## Docs Sync
- [ ] `PROGRESS.md` 已同步里程碑与 TODO/DONE
- [ ] `MEMORY.md` 已沉淀复用经验
- [ ] `NEXT_STEP.md` 已更新为单条下一步指针
```
