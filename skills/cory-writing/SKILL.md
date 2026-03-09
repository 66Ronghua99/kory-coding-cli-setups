---
name: cory-writing
description: 按照 writings 内容库规范，创建和管理每日计划（Daily Plan）与思考碎片（Memory）。包括模板复制、frontmatter 填写、文件命名和状态管理。
---

# Cory Writing: 每日计划与思考碎片管理

## Goal

帮助 agent 按照 writings 仓库规范，正确创建和维护：
1. **每日计划 (Daily Plan)** - 记录每日 TODO、复盘和灵感
2. **思考碎片 (Memory)** - 记录想法、观察、问题

确保符合以下规范：
- 文件命名正确（`YYYY-MM-DD.md`）
- 模板结构完整
- Frontmatter 符合标准
- 状态流转正确

## Hard Constraints (Non-Negotiable)

1. **模板约束**：必须复制 `_template/daily.md` 或 `_template/memory.md` 作为模板
2. **命名约束**：
   - Daily Plan: `_daily/YYYY-MM-DD.md`
   - Memory: `memory/YYYY-MM-DD_title.md`
3. **Frontmatter 约束**：
   - Daily: `type: diary`, `status: draft`, `tags: [daily]`
   - Memory: `type: memory`, `status: raw`
4. **日期约束**：使用当前日期（2026-03-09）或用户指定的日期
5. **状态约束**：
   - Memory 状态：`raw` → `mined` → `archived`
   - Daily 状态：创建时为 `draft`

## Step 0: 确认内容类型

根据用户指令判断：

| 用户意图 | 内容类型 | 目标文件夹 |
|---------|---------|-----------|
| "写日记" / "每日计划" / "daily" | Daily Plan | `_daily/` |
| "思考碎片" / "想法" / "memory" / "idea" | Memory | `memory/` |

若用户未明确指定，询问确认。

## Step 1: 检查模板文件存在

必须确认以下模板文件存在：

1. `_template/daily.md` - 每日计划模板
2. `_template/memory.md` - 思考碎片模板

若模板不存在或内容异常，报错并提示检查 `_template/` 目录。

## Step 2: 确认目标目录

| 内容类型 | 目标目录 | 目录存在性检查 |
|---------|---------|--------------|
| Daily Plan | `_daily/` | 若不存在，需创建 |
| Memory | `memory/` | 若不存在，需创建 |

创建目录（若需要）：
```bash
mkdir -p _daily
mkdir -p memory
```

## Step 3: 生成文件名

### Daily Plan 文件名

格式：`YYYY-MM-DD.md`

- 使用当前日期或用户指定日期
- 示例：`2026-03-09.md`

### Memory 文件名

格式：`YYYY-MM-DD_title.md`

- 日期 + 下划线 + 简短标题（英文/拼音）
- 标题应反映想法的核心主题
- 示例：`2026-03-09_ai-thinking.md`

## Step 4: 复制模板并填充

### 复制模板

```bash
# Daily Plan
cp _template/daily.md _daily/YYYY-MM-DD.md

# Memory
cp _template/memory.md memory/YYYY-MM-DD_title.md
```

### 填充 Frontmatter

根据内容类型填充不同的 frontmatter 字段：

**Daily Plan Frontmatter：**
```yaml
---
title: "YYYY-MM-DD Daily Plan"
date: YYYY-MM-DD
type: diary
status: draft
tags: [daily]
mood:       # 可选：happy, neutral, low, excited
summary: "今日核心主题一句话"
---
```

**Memory Frontmatter：**
```yaml
---
title: "标题"
date: YYYY-MM-DD
type: memory
status: raw
tags: []
category:  # idea | question | insight | observation
summary: "一句话概述这个想法"
---
```

### 填写正文内容

**Daily Plan 必填字段：**
- 今日核心主题（一句话，在 > 引用中）
- P0/P1/P2 优先级 TODO

**Memory 必填字段：**
- 一句话概述（> 引用）
- 背景（什么触发了这个想法）
- 思考碎片（核心内容）

可选字段根据模板提示填写。

## Step 5: 状态管理

### Memory 状态流转

| 状态 | 含义 | Agent 操作 |
|------|------|----------|
| `raw` | 初始记录 | 创建时默认 |
| `mined` | 已挖掘为选题 | 用户确认后更新 |
| `archived` | 已归档 | 不再维护 |

### 更新状态

```bash
# 更新 Memory 状态为 mined
# 修改 frontmatter 中 status: raw → status: mined
```

## Step 6: 更新索引（可选）

如果用户要求更新 `_index.md`，在对应区域添加记录：

```markdown
| YYYY-MM-DD | 标题 | 📝 草稿 | diary/memory |
```

## Validation Checklist

执行后必须验证：

- [ ] 文件存在于正确目录（`_daily/` 或 `memory/`）
- [ ] 文件名格式正确
- [ ] Frontmatter 包含必需字段
- [ ] 模板结构完整（章节标题存在）
- [ ] 日期格式正确（YYYY-MM-DD）

## Output Contract

每次执行后输出：

1. **Created File**: 文件路径
2. **Content Type**: Daily Plan / Memory
3. **Status**: 当前状态
4. **Validation**: 验证清单结果
5. **Next Actions**: 建议的后续操作（如填写 TODO、更新状态等）

## Cross-Skill 提示

此 skill 可与以下 skill 配合使用：

- **syncdoc**: 定期同步项目进度时，可同时更新每日计划
- **content-creator-collab**: 当 memory 被标记为 `mined` 后，可转化为内容选题

## Appendix: 快速命令参考

```bash
# 创建今日 Daily Plan
cp _template/daily.md _daily/2026-03-09.md

# 创建 Memory
cp _template/memory.md memory/2026-03-09_title.md

# 更新 Memory 状态
# 编辑文件 frontmatter 中的 status 字段
```
