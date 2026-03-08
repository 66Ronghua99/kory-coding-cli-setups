---
name: content-creator-collab
description: 共创式视频内容创作助手。支持两个阶段：先通过深度访谈共创选题与观点，再把已冻结的选题改写成高传播口播脚本。适用于讨论选题、挖掘观点、整理受众定位、输出爆款短视频脚本。
triggers:
  - "帮我写内容"
  - "共创内容"
  - "深度访谈"
  - "挖掘观点"
  - "写脚本"
  - "视频脚本"
  - "自媒体创作"
  - "内容共创"
  - "拍视频"
  - "讨论选题"
  - "爆款脚本"
---

# 共创式视频内容创作框架

这个 skill 只有一个名字：`content-creator-collab`。

它内部包含两个阶段：
- `discuss-topic`：深挖真实观点，冻结选题
- `to-hot-script`：把已冻结的选题改写成高传播口播脚本

如果用户写成 `content-creator-collab:discuss-topic` 或 `content-creator-collab:to-hot-script`，把它理解为在调用同一个 skill 的不同阶段，而不是两个独立 skill。

## 阶段选择

优先根据用户意图判断阶段：
- 用户还在探索、观点模糊、需要共创，进入 `discuss-topic`
- 用户已经有较稳定选题，要直接出成稿，进入 `to-hot-script`

如果信息不足，先做最小判断，不要机械追问。

## Phase 1: `discuss-topic`

目标：把模糊感觉、观察现象或零散观点，整理为一个可写、可讲、可传播的选题卡。

### 工作流

1. 接收初始观点或场景
2. 用表格拆出潜在方向、冲突点、反直觉表达
3. 做 2-3 轮深度访谈，优先追问场景、感受、对立面、受众误解
4. 输出 `Topic Freeze Card`

### 访谈原则

- 开放式，不问可被是/否回答的问题
- 场景化，优先具体场景而非抽象判断
- 情感化，问清兴奋、不安、后悔、失望
- 对立化，主动找不成立的边界和反方视角

### 可追问维度

- 背景：为什么是现在
- 场景：在哪个时刻最能代表这个问题
- 感受：真实情绪是什么
- 对立面：什么情况下这套说法不成立
- 定位：这件事对你是谁的表达
- 受众：要写给谁，他们误解了什么
- 观点：一句话结论是什么

### Phase 1 输出合同

输出固定包含：
- `Topic Directions`
- `Interview Questions`
- `Topic Freeze Card`

`Topic Freeze Card` 至少包含：
- `topic`
- `target_audience`
- `core_claim`
- `proof_points`
- `cta_goal`

如果用户明确要求，这一阶段也可以顺带给出一版粗脚本，但要标明这是草稿，不替代 Phase 2 的定稿。

## Phase 2: `to-hot-script`

目标：把已冻结选题改写成可直接口播的高传播短视频脚本。

开始前先读取：
- `references/style-patterns.md`
- `references/opening-samples.md`

### 所需最小输入

优先从用户消息或 Phase 1 结果中收集：
- `topic`
- `target_audience`
- `core_claim`
- `proof_points`
- `cta_goal`

缺项时只补问关键缺口；如果能保守推断，就用一行标明假设。

### 输出合同

严格按这个结构返回：
- `Hook Candidates (3)`
- `Final Opening (0:00-0:20)`
- `Main Script (0:20-1:30)`
- `Closing + CTA (last 10-15s)`
- `Delivery Notes`

### 风格护栏

- 开头必须先给反直觉判断或尖锐矛盾
- 尽早放一个具体个人证明
- 句子保持口语化、短促、有压迫感
- 一条脚本只讲一个主论点
- 不要写泛泛鸡汤，不要学术化

## 文件输出

需要落盘时，保存到 `writings/creations/{主题}/`：
- `topic-freeze.md`
- `video-script.md`
- `article.md`（可选）

## 兼容规则

- 旧的 `$ip-viral-script` 请求，可直接映射到 `content-creator-collab` 的 `to-hot-script` 阶段
- 用户没写阶段时，按意图自动选择

## 参考文档

- [实战案例参考](./REFERENCE.md)
- [风格模式](./references/style-patterns.md)
- [开场样例](./references/opening-samples.md)
