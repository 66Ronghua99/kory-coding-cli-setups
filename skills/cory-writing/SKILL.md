---
name: cory-writing
description: 按照 writings 内容库规范，创建和管理每日计划（Daily Plan）与思考碎片（Memory），并提供安全的 Git 操作指南，避免 OpenCLAW 与用户操作产生冲突。
---

# Cory Writing: 内容库管理与 Git 安全操作

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

---

# writings 文件夹管理指南（OpenCLAW 专用）

> 本章节专门为 OpenCLAW 等 Agent 提供，避免操作 writings 时产生 Git 冲突

## 核心原则

**Agent 严禁执行的 Git 操作：**
- ❌ `git commit`
- ❌ `git push`
- ❌ `git pull`（带自动合并）
- ❌ `git merge`
- ❌ `git rebase`
- ❌ `git reset --hard`
- ❌ `git checkout -- .`（丢弃本地修改）

**Agent 可以执行的 Git 操作：**
- ✅ `git status` - 查看当前状态
- ✅ `git diff` - 查看修改内容
- ✅ `git stash` - 临时保存本地修改
- ✅ `git stash pop` - 恢复本地修改

## 写入文件前的安全检查

### 检查清单（写入前必做）

```bash
# 1. 查看当前 git 状态
git status

# 2. 检查是否有未提交的本地修改
# 若有 Untracked files 可以继续
# 若有 modified files，谨慎处理
```

### 安全情况判断

| 状态 | Agent 操作 |
|------|----------|
| `Untracked files` only | ✅ 安全，可以创建新文件 |
| `Changes not staged` | ⚠️ 询问用户如何处理 |
| `Changes to be committed` | ⚠️ 不要添加新文件，询问用户 |
| 干净状态 (nothing to commit) | ✅ 安全 |

## 写入文件流程

### Step 1: 检查 git 状态

```bash
git status
```

### Step 2: 判断是否可以写入

- 若只有 `Untracked files` → 可以创建
- 若有本地修改 → 询问用户

### Step 3: 创建/编辑文件

按本 skill 规范创建 Daily Plan 或 Memory

### Step 4: 报告修改

写入完成后，报告：
- 创建了哪些文件
- 建议用户后续手动 `git add` 和 `commit`

## 冲突预防策略

### 1. 分散存放

Agent 创建的文件分散在不同子目录：
- `_daily/` - 每日计划
- `memory/` - 思考碎片
- `YYYY-MM/` - 每月内容

避免与用户正在编辑的文件冲突。

### 2. 小步提交建议

创建文件后，输出以下提示：

```
📝 文件已创建，请手动执行：
git add _daily/2026-03-09.md
git commit -m "feat: add daily plan for 2026-03-09"
```

### 3. 禁止自动合并

如果 `git pull` 可能产生冲突，Agent 必须：
1. 先 `git stash`
2. 询问用户是否继续
3. 或建议用户手动处理

## 紧急情况处理

### 情况：用户正在编辑同一文件

**错误做法：** 直接覆盖用户修改
**正确做法：**
1. 询问用户
2. 或使用 `git diff` 比较差异后合并

### 情况：产生冲突

**错误做法：** 强制提交
**正确做法：**
1. 停止操作
2. 报告冲突文件列表
3. 等待用户手动解决

## OpenCLAW 特殊提示

- OpenCLAW 以独立进程运行，可能与用户操作同时进行
- 始终假设用户可能在本地手动编辑文件
- 写入前 `git status` 是强制检查
- 不确定时优先询问用户
