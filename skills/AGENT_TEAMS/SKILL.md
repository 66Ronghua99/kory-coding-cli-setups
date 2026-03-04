---
name: agent-teams-reference
description: Working principles, terminology, and communication Protocols for Agent Teams. A guideline for Team Leads and Team Members regarding task allocation, acceptance, execution, and reporting. 
---

# Agent Teams 协作协议

> 适用于所有参与多代理协作的 Claude Code Agent，包括 Team Lead 和 Teammate。

---

## 角色定义

### Team Lead (主代理)
- **职责**: 任务规划、团队协调、结果整合
- **行为准则**:
  - 使用 `TeamCreate` 初始化团队
  - 使用 `TaskCreate` 拆分任务并设置依赖
  - 使用 `Agent` 创建子代理（后台并行时设置 `run_in_background: true`）
  - 通过 `SendMessage` 分配任务和查询进度
  - 任务完成后发送 `shutdown_request` 关闭代理
  - 最终使用 `TeamDelete` 清理团队

### Teammate (子代理)
- **职责**: 执行具体任务、主动汇报、及时沟通
- **行为准则**:
  - 启动后立即通过 `TaskList` 查看可用任务
  - 使用 `TaskUpdate` 认领任务（设置 owner 和 status: "in_progress"）
  - 通过 `SendMessage` 向 Leader 汇报进度和结果
  - 遇到阻塞立即通知 Leader，不要等待
  - 收到 `shutdown_request` 后回复 `shutdown_response` 并退出

---

## 任务生命周期

```
pending → in_progress → completed
   ↑                        ↓
   └──────────────────── deleted
```

### Teammate 任务执行流程

1. **查询任务**: 调用 `TaskList`，筛选 `status: "pending"` 且 `blockedBy: []` 且 `owner: null` 的任务
2. **认领任务**: `TaskUpdate({ taskId, owner: "your-name", status: "in_progress" })`
3. **执行任务**: 按照任务描述完成工作
4. **汇报进度** (关键节点): 向 Leader 发送消息说明进展
5. **完成任务**: `TaskUpdate({ taskId, status: "completed" })`
6. **发送成果**: 通过 `SendMessage` 向 Leader 汇报完整结果

---

## 消息通信规范

### 消息类型

| 类型 | 用途 | 必填字段 |
|------|------|----------|
| `message` | 普通通信 | `recipient`, `content`, `summary` |
| `shutdown_request` | 请求关闭代理 | `recipient` |
| `shutdown_response` | 响应关闭请求 | `request_id`, `approve` |

### Team Lead → Teammate 消息模板

**分配任务**:
```
任务: [简述]
上下文: [背景信息]
要求: [具体产出]
完成标准: [如何判断完成]
```

**查询进度**:
```
请汇报任务进度：
- 当前完成百分比
- 遇到的主要问题
- 预计完成时间
```

### Teammate → Team Lead 消息模板

**进度汇报**:
```
进度: [百分比或阶段]
已完成: [具体工作]
阻塞: [如果有]
下一步: [计划]
```

**任务完成汇报**:
```
任务 [taskId] 已完成。
产出: [文件路径/代码/文档]
关键决策: [如果有]
待确认: [需要 Leader 决策的问题]
```

**请求帮助**:
```
遇到阻塞需要帮助：
问题: [描述]
已尝试: [解决方案]
需要决策: [具体问题]
```

---

## 关键规则

### Teammate 必须遵守

1. **立即领取任务**: 启动后第一件事是查看 TaskList 并认领任务
2. **及时汇报**: 关键节点必须发送消息，Leader 看不到你的输出
3. **使用名称而非 UUID**: `SendMessage` 的 `recipient` 使用代理名称（如 "team-lead"）
4. **完成后标记**: 必须调用 `TaskUpdate` 将状态改为 "completed"
5. **响应关闭请求**: 收到 `shutdown_request` 必须回复 `shutdown_response`

### Team Lead 必须遵守

1. **创建任务依赖**: 使用 `addBlockedBy` 设置任务执行顺序
2. **后台并行**: 独立任务使用 `run_in_background: true` 并行执行
3. **等待消息**: Teammate 的输出不会自动显示，需要通过消息收集结果
4. **优雅关闭**: 先发送 `shutdown_request`，确认后再 `TeamDelete`

---

## 快速参考

### Teammate 启动自检清单

```
□ 调用 TaskList 查看可用任务
□ 选择无阻塞 (blockedBy: []) 且未分配 (owner: null) 的任务
□ 调用 TaskUpdate 认领任务 (status: "in_progress")
□ 开始执行任务
□ 关键节点发送消息汇报进度
□ 完成后 TaskUpdate 标记 completed
□ 发送消息向 Leader 汇报成果
```

### 任务优先级

- 优先处理 **ID 小** 的任务（创建顺序）
- 优先处理 **阻塞其他任务** 的关键路径任务
- 优先处理 **短时间** 可完成的任务

### 工具速查

| 工具 | 用途 |
|------|------|
| `TaskList` | 查看所有任务状态 |
| `TaskGet` | 获取单个任务详情 |
| `TaskUpdate` | 更新任务状态/认领任务 |
| `SendMessage` | 与团队成员通信 |

---

## 常见错误避免

1. **❌ 不向 Leader 汇报**: Teammate 的所有输出对 Leader 不可见，必须通过 `SendMessage` 显式通信
2. **❌ 使用 UUID 作为 recipient**: `recipient` 必须是代理名称，不是 agent ID
3. **❌ 忘记标记任务完成**: 完成后必须调用 `TaskUpdate` 设置 `status: "completed"`
4. **❌ 未响应 shutdown**: 收到 `shutdown_request` 必须回复 `shutdown_response`
