# Memory 模板参考

> 此文件为 agent 提供模板参考，请勿手动修改

## 文件位置

模板源：`_template/memory.md`

## Frontmatter 格式

```yaml
---
title: "标题"
date: YYYY-MM-DD
type: memory
status: raw  # raw | mined | archived
tags: []
category:  # idea | question | insight | observation
summary: "一句话概述这个想法"
---
```

## 必填章节

1. **> 引用句** - 一句话概述这个想法
2. **## 背景** - 是什么触发了这个想法
3. **## 思考碎片** - 核心思考内容
4. **## 关联话题** - 相关话题
5. **## 后续行动**
   - [ ] 深入调研
   - [ ] 转化为内容选题
   - [ ] 与已有素材结合
   - [ ] 存档
6. **## 状态历史** - 状态变更记录

## 文件命名

- 格式：`YYYY-MM-DD_title.md`
- 标题使用英文或拼音，全小写
- 示例：`2026-03-09_ai-thinking.md`
- 目录：`memory/`

## 状态流转

| 状态 | 含义 | 说明 |
|------|------|------|
| `raw` | 初始记录 | 创建时默认状态 |
| `mined` | 已挖掘为选题 | 可转化为内容 |
| `archived` | 已归档 | 不再维护 |

## category 可选值

- `idea` - 新想法
- `question` - 问题/疑问
- `insight` - 洞察/领悟
- `observation` - 观察/发现
