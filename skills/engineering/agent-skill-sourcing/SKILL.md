---
name: agent-skill-sourcing
description: 从 GitHub 采集开源 Agent Skills/Subagents 装进本地时用。含搜索源、格式转换、验证。
---

# Agent Skill 采集与安装(从 GitHub 到本地 skills)

> 触发: 用户要求"去网上找 skill / 下载 skill / 找参考系统 / 借鉴开源项目"

## 优质资源源(2026-08 实测可用)
1. **anthropics/skills** — Anthropic 官方 skill 仓库 (frontend-design/canvas-design/webapp-testing/theme-factory/skill-creator/mcp-builder/docx/pdf/pptx/xlsx)
   - `git clone --depth 1 https://github.com/anthropics/skills.git`
   - 结构: skills/<name>/SKILL.md + scripts/ + references/
2. **VoltAgent/awesome-agent-skills** — 1000+ skills 索引 (README 175KB 是链接索引, 不直接 clone 内容)
   - 实际内容在各官方仓库 (Stripe/Cloudflare/Vercel/Notion...)
3. **VoltAgent/awesome-claude-code-subagents** — 168 个 subagent 角色 .md
   - `git clone --depth 1 https://github.com/VoltAgent/awesome-claude-code-subagents.git`
   - categories/ 下 10 个分类, 每个 .md 有 frontmatter (name/description/tools/model) — 与 SKILL.md 格式兼容!
4. **btLong402/backend-architect-skill** — 后端架构知识库 skill (含 search.py 脚本 + CSV 数据库)
   - .claude/skills/backend-architect/SKILL.md (引用相对路径 scripts/search.py)
   - **实际数据在 .shared/backend-architect-skill/ 目录** — 复制时要用 .shared 的 scripts+data, 不是 .claude 的!
5. **Eskyee/agentbot-opensource** — 多租户 AI Agent 平台开源 (DID 身份/信任分/OpenClaw 集成), 做平台设计参考

## 搜索技巧(智谱 MCP)
- `tool_call(mcp__zhipu_web_search__web_search_prime, {search_query, content_size:high})`
- 关键词: "github awesome agent skills", "anthropics skills", "<领域> SKILL.md", "claude code subagents"
- zread `get_repo_structure` 看目录, `read_file` 读文件(>100KB 会被 persisted 到 /tmp/hermes-results/)

## 安装流程
1. clone 到 /home/agent/workspace/skill-sources/
2. 检查格式: `head -6 SKILL.md` 看 frontmatter (name/description 必须有, description ≤60 字符)
3. 复制到 ~/.hermes/skills/<category>/<name>/ (creative 或 software-development)
   - **子目录复制要用 -r 且确认 scripts/data 都在**(backend-architect 教训: SKILL.md 引用相对路径, 数据在 .shared/)
4. 验证: `skills_list(category=...)` 确认注册; 有脚本的先跑 `python3 scripts/xxx.py --help` 测通
5. 多文件 skill 用 `skill_manage(action=write_file)` 存 references/scripts/ (文件放 assets/references/scripts/templates 下)

## 陷阱
- description 超 60 字符会被拒 (skill_manage create 报错) — 精简到一句话+触发词
- frontmatter 必须 YAML 合法 (name/description 双引号包裹的会被解析)
- VoltAgent 的 subagent .md 有 tools/model frontmatter — Hermes 忽略多余字段, 保留 name/description 即可
- 一次性批量转换写脚本到 /opt/data/ (workspace 目录写受限, HERMES_WRITE_SAFE_ROOT=/opt/data)
- 大文件读取: 智谱 read_file 超 100KB 自动 persisted 到 /tmp/hermes-results/<id>.txt, 用 read_file 分页读

## 指挥编程 agent 时加载
- claude/codex/opencode 支持 SKILL.md 格式 (SKILL.md + 目录结构)
- 把 ~/.hermes/skills/software-development/<name>/ 复制到远程 agent 工作区 .claude/skills/ 或直接传 SKILL.md 内容
- 120 上已装 claude 2.1.232 / codex 0.50.0 / opencode 1.18.18
