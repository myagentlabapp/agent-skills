---
name: skill-discovery
description: "Use when finding third-party agent skills online."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [skills, discovery, search, hermes-hub, skills.sh]
---

# 在线技能发现（找现成 skill 给 Agent 用）

用户说「去查一下网上有没有做 XX 的 skill」「找一下怎么干 XX 的 skill」时用。目标：快速列出候选 + 安装量/来源/一句话用途，让用户挑，而不是现场造轮子。

## When to Use

- 「网上有没有做网页系统的 skill」「找一下指挥 claude codex opencode 干活的 skill」
- 「装个 XX 的 skill」「有没有现成的 skill 能…」
- 用户想知道某个能力社区/官方有没有现成实现

## 搜索源（按效率排序）

### 1. skills.sh API（最快，免登录）
```bash
curl -s -m 15 "https://skills.sh/api/search?q=<关键词>" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for s in d.get('skills',[])[:12]:
    print(f\"{s['id']}  (installs: {s['installs']})\")
"
```
返回 `id`（格式 `owner/repo/skill-name`）+ 安装量。关键词用英文单复数都试（web、dashboard、delegate、orchestration、claude-code、subagent…）。

### 2. GitHub 仓库搜索
```bash
curl -s -m 20 "https://api.github.com/search/repositories?q=hermes+skills&sort=stars&per_page=10"
```
看 `full_name` + `stargazers_count` + `description`。已知高星目录仓库：`0xNyk/awesome-hermes-agent`（技能/插件/工具目录）、`ChuckSRQ/awesome-hermes-skills`。

### 3. Hermes 内置 hub 源（搜到了要装的时候）
`hermes skills install <id>` 支持多源：`official`（官方可选）、`skills-sh`、`github`（默认 tap：openai/skills、anthropics/skills、huggingface/skills、NVIDIA/skills）、`clawhub`、`lobehub`、`browse-sh`。用法示例：
```bash
hermes skills search web --source skills-sh   # 搜
hermes skills inspect <id>                     # 预览
hermes skills install <id>                     # 装（带安全扫描）
```
文档：https://hermes-agent.nousresearch.com/docs/user-guide/features/skills

## 已发现的高价值技能（2026-08-15 实测）

### 网页/前端类
| Skill | 安装量 | 用途 |
|---|---|---|
| `vercel-labs/agent-skills/web-design-guidelines` | 54万 | UI 合规审查（100+ 规则） |
| `anthropics/skills/webapp-testing` | 13万 | 网页应用测试（官方） |
| `anthropics/skills/web-artifacts-builder` | 9.2万 | 构建网页制品/前端（官方） |
| `firecrawl/firecrawl-workflows/firecrawl-website-design-clone` | 3.1万 | 克隆参考站设计 |
| `cloudflare/skills/web-perf` | 4.4万 | 网页性能 |
| `nexu-io/open-design`（GitHub, 78k stars） | — | 31 个网页/移动/仪表盘 skill，129 设计系统，支持 Hermes |

### 编排/指挥 CLI agent 类（claude/codex/opencode）
| Skill | 安装量 | 用途 |
|---|---|---|
| `amelnagdy/delegate-skills/claude-delegate` / `codex-delegate` / `opencode-delegate` | 各 1-2.3k | 写 brief → 后台派发独立进程 → 审 diff → 自己落地；`delegate-setup` 统管全套 |
| `obra/superpowers/subagent-driven-development` | 17.6万 | 每任务一个新鲜 subagent，做完即审（superpowers 116k stars，含 dispatching-parallel-agents / executing-plans） |
| `anthropics/claude-code/agent-development` | 1.7万 | 官方 agent 开发指南 |
| `openai/codex/babysit-pr` | 3.2k | Codex 官方 PR 托管 |

## Pitfalls

- **hermes CLI 可能不在 PATH**：`which hermes` 找不到时查 `/opt/hermes/bin/hermes`（本机实际位置），或看 `~/.hermes/bin/`。直接跑 `hermes skills search` 前先确认。
- **GitHub raw 文件分支可能是 master 不是 main**：`amelnagdy/delegate-skills` 的 raw URL 用 main 会 404，必须 master。先 `api.github.com/repos/<owner>/<repo>` 或 contents API 拿到真实默认分支再拼 raw URL。
- **skills.sh 搜索是模糊匹配**：`claude code` 带空格会搜不到（API 报错），用 `claude-code` 或单关键词。
- **先翻本机 skills_list 再说"网上找"**：很多能力本机已有（本会话发现用户已有 claude-code/codex/opencode/agent-orchestration/superpowers 系列），网上搜之前先 `skills_list` 确认缺口，避免推荐用户装已有能力的重复品。
- **装之前给用户表格对比**：候选 skill 用表格给（id / 安装量 / 一句话用途 / 来源），末尾给明确推荐 + 问是否安装。用户偏好先结论后细节。

## Verification

- 给用户看的每条推荐都要有真实来源（skills.sh id + 安装量，或 GitHub stars）——不许凭记忆编安装量。
- 声称「本机已有」之前用 skills_list 确认。
