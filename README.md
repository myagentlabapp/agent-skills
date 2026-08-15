# myagentlab Agent Skills

智体工坊（myagentlab）沉淀的精选 Agent Skills 集合——从全网高星开源 skill 仓库中筛选出的**通用、无内部依赖**的高价值技能，供团队所有 Agent 快速部署使用。

## 为什么有这个仓库

我们从 16+ 个开源 skill 仓库（obra/superpowers、anthropics/skills、mattpocock/skills、addyosmani/agent-skills、am-will/swarms 等）筛选出**纯方法论、无内部凭据**的 skill，统一管理、统一安装。内部业务 skill（含内网地址/凭据）**不在此仓库**。

## 目录结构

```
skills/
├── orchestration/   # 多 Agent 编排与并行调度
├── engineering/     # 软件工程方法论（review/tdd/refactor/debug）
└── marketing/       # 营销与增长（copywriting/seo/cro/launch）
```

## 快速安装

```bash
git clone https://github.com/myagentlabapp/agent-skills.git
cd agent-skills
./install.sh          # 默认安装到 ~/.hermes/skills/
# 或指定目标目录：
INSTALL_DIR=/path/to/skills ./install.sh
```

安装脚本会：创建目标目录 → 按 `skills/<category>/<name>` 复制 → **同名已存在时跳过，不覆盖本地版本**。

## Skill 清单与来源

### orchestration（6）— 多 Agent 编排

| Skill | 来源 |
|-------|------|
| super-swarm | am-will/swarms — rolling pool 并行调度，谁先完成谁先派下一个 |
| parallel-task | am-will/swarms — 依赖感知的分波次并行派发 |
| parallel-task-tmux | am-will/swarms — tmux 实时 pane 跟踪并行任务 |
| swarm-planner | am-will/swarms — 面向并行执行的依赖感知计划 |
| co-design | am-will/swarms — 设计任务路由 |
| sub-agents | shinpr/sub-agents-skills — 跨 LLM CLI 子 Agent 路由（codex/claude/glm/kimi/grok/gemini/opencode） |

### engineering（28）— 软件工程方法论

| Skill | 来源 |
|-------|------|
| code-review / implement / tdd / domain-modeling / diagnosing-bugs / resolving-merge-conflicts | mattpocock/skills |
| subagent-driven-development / executing-plans / writing-plans / verification-before-completion / dispatching-parallel-agents / spec-driven-development | obra/superpowers |
| code-simplification / security-and-hardening / context-engineering / planning-and-task-breakdown / api-and-interface-design / debugging-and-error-recovery / performance-optimization / observability-and-instrumentation / ci-cd-and-automation / git-workflow-and-versioning | addyosmani/agent-skills |
| safe-refactor / surgical-patch / lean-build / verify-and-stop / investigate-first | JuliusBrussee/caveman |
| karpathy-guidelines | multica-ai/andrej-karpathy-skills |

### marketing（11）— 营销与增长

| Skill | 来源 |
|-------|------|
| copywriting / content-strategy / ai-seo / cro / pricing / launch / cold-email / analytics / marketing-plan / customer-research / competitor-profiling | coreyhaines31/marketingskills |

## 许可与致谢

本仓库是**第三方开源 skill 的精选合集**，每个 skill 保留其原始仓库的 license。来源：

- [obra/superpowers](https://github.com/obra/superpowers)（272k★）
- [mattpocock/skills](https://github.com/mattpocock/skills)（218k★）
- [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)（87k★）
- [am-will/swarms](https://github.com/am-will/swarms)
- [shinpr/sub-agents-skills](https://github.com/shinpr/sub-agents-skills)
- [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)（98k★）
- [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)
- [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills)（44k★）

如需商用，请查阅各原始仓库的具体 license 条款。

## 维护

- 新增 skill：放入 `skills/<category>/<name>/`（含 SKILL.md 及引用文件），更新本 README 清单
- 更新流程：参照 `third-party-skill-install`（发现→评估→克隆→探测→安装→验证）
- 安全要求：**本仓库禁止出现**内网 IP、域名、凭据、API key
