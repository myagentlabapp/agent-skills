---
name: volcengine-ark-plans
description: 火山方舟 Coding Plan / Agent Plan 订阅研究与对比。触发词：方舟套餐、Coding Plan、Agent Plan、火山套餐哪个好、方舟订阅、Pro/Medium 多少钱、续费/升配决策。含价格查询技巧（活动页价格需登录→走折扣规则公告文档）+ 套餐权益对比 + 活动规则 + 推荐逻辑。
---

# 火山方舟 Coding Plan / Agent Plan 订阅研究

## 触发场景
- 用户问「方舟 Coding Plan / Agent Plan 哪个好」「订阅哪个」「Pro/Medium 多少钱」
- 续费/升配/降档决策（2.5 折优惠期结束后价格回升）
- 判断套餐能否当网关/API 上游（答案：**不能**，见坑）

## 价格怎么查（关键技巧，别卡在活动页）
活动页（volcengine.com/activity/codingplan 或 /agentplan）的价格是**登录后异步加载**的：未登录显示「价格查询中...」，network 请求也抓不到（接口要登录态）。**不要干等、不要登录**，直接：
1. 活动页找「折扣规则」「加量规则」链接 → 指向 docs.volcengine.com/docs/82379/<id> 官方公告，正文含完整价格表（静态文本，browser_console 读 innerText 即可）
2. 套餐权益/模型矩阵 → 「套餐详情/套餐概览」链接（Agent Plan 概览 = docs/82379/2366394，含价格 + 模型×档位矩阵 + AFP 额度）
3. 同目录还有「限时邀请活动」「指定模型抵扣系数限时折扣」「模型下线公告」等，一并读全再下结论

## 对比纪律（用户明确纠正过：「所以你就不对比X了？」）
用户问「A vs B 哪个好」→ 必须把**两边价格+权益都查完**再回答。只答一边就收尾 = 被追问。格式：先结论，再表格，最后当前动作/建议。

## 价格与活动规则（2026-06-08 ~ 2026-11-08，到期需重查）
| 档位 | 原价 | 活动价(首两月2.5折) | 备注 |
|---|---|---|---|
| Coding Lite | ¥40 | ¥9.9 | 纯编程模型 + Embedding |
| Coding Pro | ¥200 | ¥49.9 | 5× Lite 用量 |
| Agent Small | ¥40 | ¥9.9 | 20,000 AFP/月，无视频 |
| Agent Medium | ¥200 | ¥49.9 | 100,000 AFP，含 kimi-k3、送 ArkClaw 轻量版；视频仅 seedance-1.5-pro(即将下线) |
| Agent Large | ¥500 | 无折扣 | 250,000 AFP，seedance-2.0 全系 |
| Agent Max | ¥1000 | 无折扣 | 500,000 AFP |

规则要点：
- 首两个月 2.5 折，第三个月恢复原价；优惠资格**每账号总共 2 个月**，新购/续费/升配共享，用完不因升档/退订重新获得
- Agent Plan 模型集合是 Coding Plan 的**超集**，同价位 Agent 全面优于 Coding（多模态模型 + Harness + 图片/语音/搜索 + ArkClaw）
- kimi-k3 需 Medium 及以上；视频生成(seedance-2.0)仅 Large/Max；Small/Medium 不支持视频
- Auto 模式活动期抵扣系数 0.5，更省；夜间 00:00-8:00 kimi-k3 路由比例提升

## 推荐逻辑
- 纯编程也选 Agent（模型是 Coding 超集，同价多模态 + ArkClaw）
- 不要视频 → Medium 闭眼订（前两月 ¥99.8），2 个月后决策续(¥200)/降回 Small(¥40)
- 要视频 → 只有 Large/Max，无折扣，按需购买

## 接入方式与 Key 验证（2026-08-11 实测）
Agent Plan 接入（官方文档 docs/82379/2373738 快速开始）：
- **专属 Base URL（Anthropic 协议）**: `https://ark.cn-beijing.volces.com/api/plan`——**其他 Base URL 无法在 Agent Plan 中使用**（Coding Plan 的 `/api/coding`、`/api/coding/v3` 在 Agent Plan 里都无效）
- **专属 API Key**：必须用「Agent Plan API Key」，**其他方舟 Key（含 Coding Plan Key）在 Agent Plan 中直接认证失败**
- 模型名：`ark-code-latest`（控制台切换）或具体模型名（deepseek-v4-flash、glm-5.2、kimi-k3 等，按套餐档位）
- Claude Code 配置（settings.json）：`ANTHROPIC_AUTH_TOKEN` / `ANTHROPIC_BASE_URL` / `ANTHROPIC_MODEL`，工具支持列表同 Coding Plan（Claude Code、TRAE、Roo Code、Codex CLI、OpenCode、Cline、Kilo Code、OpenClaw、Cursor、Hermes Agent）
- 官方自动化配置：`npm install -g @volcengine/ark-cli@latest` → `arkcli auth login`（消费模式选 agent-plan）→ `arkcli helper` 自动配工具 + Harness
- 验证命令：`curl -s https://ark.cn-beijing.volces.com/api/plan/v1/messages -H "x-api-key: <key>" -H "anthropic-version: 2023-06-01" -d '{"model":"ark-code-latest","max_tokens":30,"messages":[{"role":"user","content":"hi"}]}'`
- 实测：`AuthenticationError`（Unauthorized）= key 无效或**不是 Agent Plan 专属 Key**（x-api-key 与 Bearer 两种都试过均 401）。此时停下问用户要正确的 Agent Plan 专属 Key，别继续盲试（用户极厌恶盲试 key）

## 坑
- Coding/Agent Plan **不能用于 API 调用**：在非 AI 编程工具中使用其 Base URL/Key 会被识别为滥用 → 停用/封号。不能当 new-api 网关上游卖
- 优惠资格用完即止，升配/换档不重新获得
- zhipu webReader 有 5 小时限额(429) → 备用浏览器抓取
- deepseek-v4-pro 是尝鲜体验版，拥堵/限流时切其他模型
- 刚下单订阅可能有一小段生效延迟（一般几分钟），认证失败时可稍等重试

## 参考文件
- references/ark-plans-2026-08.md — 价格/模型矩阵/AFP/工具列表数据快照（含官方文档链接）
