# 火山方舟套餐数据快照（2026-08-11 抓取，活动期 2026-06-08 ~ 2026-11-08）

## 官方文档链接
- Coding Plan 折扣规则公告: https://docs.volcengine.com/docs/82379/2525065 （Lite ¥40→9.9, Pro ¥200→49.9, 首两月2.5折）
- Agent Plan 折扣规则公告: https://docs.volcengine.com/docs/82379/2525063 （Small ¥40→9.9, Medium ¥200→49.9）
- Agent Plan 套餐概览: https://docs.volcengine.com/docs/82379/2366394 （四档价格 + 模型×档位矩阵 + AFP 额度）
- Coding Plan 套餐概览: https://docs.volcengine.com/docs/82379/1925114
- 加量规则: Coding docs/82379/2533566, Agent docs/82379/2533565（GLM-5.2 等热门模型限时加量4倍）

## Agent Plan 模型×档位矩阵（√=支持 ×=不支持）
| 模型 | Small | Medium | Large | Max |
|---|---|---|---|---|
| doubao-seed-2.0-mini / 2.0-lite | √ | √ | √ | √ |
| deepseek-v4-flash / deepseek-v4-pro | √ | √ | √ | √ |
| doubao-seed-2.1-turbo / doubao-seed-evolving | √ | √ | √ | √ |
| doubao-seed-2.0-code / 2.0-pro（即将下线） | √ | √ | √ | √ |
| minimax-m2.7（即将下线）/ minimax-m3 | √ | √ | √ | √ |
| glm-5.2 (glm-latest) | √ | √ | √ | √ |
| kimi-k2.6（即将下线）/ kimi-k2.7-code | √ | √ | √ | √ |
| **kimi-k3** | **×** | √ | √ | √ |
| doubao-embedding-vision 向量化 | √ | √ | √ | √ |
| doubao-seedream-5.0-lite 图片 | √ | √ | √ | √ |
| doubao-seedance-1.5-pro 视频（即将下线） | × | √ | √ | √ |
| **seedance-2.0 / 2.0-fast / 2.0-mini 视频** | **×** | **×** | √ | √ |
| doubao-seed-tts-2.0 语音合成 | √ | √ | √ | √ |
| doubao-seed-asr-2.0 语音识别 | √ | √ | √ | √ |
| 豆包搜索 Harness | √ 500次/月 | √ 500次/月 | √ 500次/月 | √ 500次/月 |
| Agent 记忆 / AI Native 底座 / Agent 进化 / 专业数据集 | √ | √ | √ | √ |

## 上下文长度亮点（1024k/1M 窗口）
- glm-5.2（输出128k）、deepseek-v4-flash（输出384k）、deepseek-v4-pro（输出384k）、kimi-k3（输出128k）、minimax-m3（输出128k）、doubao-seed-evolving（输出256k）→ 1M 上下文，适合大型代码库长会话
- 其他模型多为 256k 窗口；kimi-k2.6/k2.7-code 输出 32k

## AFP 月额度与限额
- Small 20,000 / Medium 100,000 / Large 250,000 / Max 500,000
- 图片/视频/语音/Harness 无 5 小时与周限额，仅受模型日额度 + 套餐月额度
- 文本模型有 5 小时限额 + 周限额 + 月限额
- Auto 模式抵扣系数 0.5（2026-06-10 18:00 ~ 2026-11-08 23:59），夜间 00:00-8:00 kimi-k3 路由比例大幅提升
- Small/Medium 轻量化体验，**不支持视频生成**，官方建议视频需求选 Large/Max

## Coding Plan 支持的编程工具
Claude Code、TRAE、Roo Code、Codex CLI、OpenCode、Cline、Kilo Code、OpenClaw、Cursor、Hermes Agent
- Base URL: `https://ark.cn-beijing.volces.com/api/coding/v3`（OpenAI 兼容协议）或 `/api/coding`（Anthropic 兼容）
- 必须用指定 Base URL 才消耗套餐额度，否则产生额外 API 费用
- 套餐额度仅在 AI 编程工具中生效，不可用于 API 调用（违规→停用/封号）

## Agent Plan 接入（快速开始文档 docs/82379/2373738）
- 专属 Base URL（Anthropic 协议）: `https://ark.cn-beijing.volces.com/api/plan`——其他 URL（含 Coding Plan 的 /api/coding）无法使用
- 必须用 Agent Plan 专属 API Key；其他方舟 Key（Coding Plan Key 等）认证失败
- 模型名: `ark-code-latest` 或具体模型名（按套餐档位，见上方模型矩阵）
- Claude Code settings.json: ANTHROPIC_AUTH_TOKEN=<Agent Plan Key>, ANTHROPIC_BASE_URL=https://ark.cn-beijing.volces.com/api/plan, ANTHROPIC_MODEL=<模型名>, 建议 HAIKU/SONNET/OPUS/SUBAGENT 全设为同一模型
- 支持工具与 Coding Plan 相同（含 Hermes Agent）
- 官方自动化: `npm install -g @volcengine/ark-cli@latest` → `arkcli auth login`（Type 选 agent-plan）→ `arkcli helper` 选 profile `agent-plan_cn-beijing_personal` 自动配置
- 验证端点: POST `https://ark.cn-beijing.volces.com/api/plan/v1/messages` + `x-api-key` 头 + `anthropic-version: 2023-06-01`
- 2026-08-11 实测: 非专属 Key 在该端点返回 `AuthenticationError: The API key or AK/SK in the request is missing or invalid`（401），x-api-key 与 Bearer 均如此

## 活动规则细节
- 优惠资格按账号维度，最多首两月 2.5 折；新购/续费/升配共享同一次资格，用完不返还
- 首月只订 1 个月特惠 → 第二个月特惠操作需在首月购买成功次日起才能进行
- 老用户：已有 Lite/Small 可续费或升配享首两月折扣（不满 1 个月按 1 个月计）
- 邀请裂变：每邀请一位好友下单得 5% 代金券（上不封顶），好友首次订阅 9.5 折，可与普惠活动叠加
- 同一手机号/证件号/账号视为同一用户，多账号刷单会被取消资格
