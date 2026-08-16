# myagentlab Agent Skills

智体工坊（myagentlab）沉淀的精选 Agent Skills 集合——从全网高星开源 skill 仓库与聚合站（skills.sh / lobehub / mcpservers / mcpmarket）筛选出的**通用、无内部依赖**的高价值技能，供团队所有 Agent 快速部署使用。

## 为什么有这个仓库

我们从 20+ 个开源 skill 仓库（obra/superpowers、anthropics/skills、mattpocock/skills、addyosmani/agent-skills、am-will/swarms、affaan-m/ECC、samber/cc-skills 等）筛选出**纯方法论、无内部凭据**的 skill，统一管理、统一安装。内部业务 skill（含内网地址/凭据）**不在此仓库**。

## 目录结构

```
skills/
├── orchestration/   # 多 Agent 编排、并行调度、Agent 架构
├── engineering/     # 软件工程方法论（架构设计/代码设计/代码审查/后端/前端/数据/工程流程）
├── testing/         # 测试全家桶（E2E/API/性能/安全/单元/可访问性/移动/LLM）
├── marketing/       # 营销与增长（copywriting/seo/cro/launch）
└── research/        # 深度研究（deep-research 中英双语）
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

### orchestration（26）— 多 Agent 编排与 Agent 架构

| Skill | 来源 |
|-------|------|
| super-swarm / parallel-task / parallel-task-tmux / swarm-planner / co-design | am-will/swarms |
| sub-agents | shinpr/sub-agents-skills |
| agent-architecture-audit / agent-eval / agent-self-evaluation / agentic-engineering / autonomous-agent-harness / agent-harness-construction / autonomous-loops / continuous-agent-loop / team-agent-orchestration / team-builder / dev-team / council / council-multi-model / context-budget / token-budget-advisor / cost-aware-llm-pipeline / prompt-optimizer / ecc-guide / ecc-recipes / benchmark-optimization-loop | affaan-m/ECC |

### engineering（88）— 软件工程方法论

| 分组 | Skill | 来源 |
|------|-------|------|
| 核心流程 | code-review / implement / tdd / domain-modeling / diagnosing-bugs / resolving-merge-conflicts | mattpocock/skills |
| 方法论 | subagent-driven-development / executing-plans / writing-plans / verification-before-completion / dispatching-parallel-agents / spec-driven-development | obra/superpowers |
| 生产工程 | code-simplification / security-and-hardening / context-engineering / planning-and-task-breakdown / api-and-interface-design / debugging-and-error-recovery / performance-optimization / observability-and-instrumentation / ci-cd-and-automation / git-workflow-and-versioning | addyosmani/agent-skills |
| 省 token | safe-refactor / surgical-patch / lean-build / verify-and-stop / investigate-first | JuliusBrussee/caveman |
| 准则 | karpathy-guidelines | multica-ai/andrej-karpathy-skills |
| 架构 | hexagonal-architecture / blueprint / architecture-decision-records / intent-driven-development / contract-first / codebase-onboarding / code-tour / repo-scan / workspace-surface-audit / inherit-legacy-style / living-docs-governance / search-first / parallel-execution-optimizer | affaan-m/ECC |
| 后端 | python-patterns / python-testing / fastapi-patterns / django-patterns / django-security / django-tdd / django-verification / api-connector-builder / error-handling / database-migrations / postgres-patterns / mysql-patterns / redis-patterns / prisma-patterns | affaan-m/ECC |
| 前端 | frontend-a11y / frontend-design-direction / make-interfaces-feel-better / liquid-glass-design / ui-demo / ui-to-vue / react-patterns / react-performance / react-testing / vue-patterns / vite-patterns | affaan-m/ECC |
| 部署 | docker-patterns / deployment-patterns / kubernetes-patterns / site-launch-checklist / canary-watch / production-audit / gateguard / security-scan / snyk-agent-scan-compliance | affaan-m/ECC + samber/cc-skills |
| 工程流程 | plan-orchestrate / orch-add-feature / orch-build-mvp / orch-change-feature / orch-fix-defect / orch-pipeline / orch-refine-code / delivery-gate / browser-qa / ai-regression-testing / conventional-git / skill-progressive-disclosure-design / chrome-extension | affaan-m/ECC + samber/cc-skills |

### engineering（1380）— 架构设计 / 代码设计 / 代码审查（2026-08-16 扩充）

第三轮扩充聚焦**代码设计、架构设计、代码审查**三方面，来源：

| 来源 | 数量 | 覆盖 |
|------|------|------|
| [wshobson/agents](https://github.com/wshobson/agents)（39k★） | 174 | 架构（architecture-patterns / microservices-patterns / cqrs-implementation / event-store-design / saga-orchestration）、代码质量（python-anti-patterns / python-design-patterns / error-handling-patterns / memory-safety-patterns）、API 设计（api-design-principles / openapi-spec-generation）、审查（multi-reviewer-patterns / review-agent-setup）、前端设计（design-system-patterns / interaction-design / visual-design-foundations） |
| [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills)（24k★） | 319 | 工程团队（engineering / engineering-team 目录：code-review / architecture / tdd / api-design）、质量保障（ra-qm-team）、产品工程（product-team / productivity）等 |
| [sickn33/agentic-awesome-skills](https://github.com/sickn33/agentic-awesome-skills)（45k★） | 594 | **架构**：ddd-strategic-design / ddd-tactical-patterns / domain-driven-design / event-sourcing-architect / c4-architecture / monorepo-architect / software-architecture / architect-review / cloud-architect / kubernetes-architect / hybrid-cloud-architect；**审查**：code-review-checklist / code-review-ai-ai-review / comprehensive-review / git-pr-review / codex-review / review-swarm / differential-review / production-code-audit / codebase-audit-pre-push / styleseed-design-review；**代码设计**：clean-code / clean-code-guard / code-refactoring-* / codebase-cleanup-* / unslop / vibe-code-auditor / fp-*（函数式设计）/ design-it（48 种 UI 风格）/ super-code（16 语言编码规范） |
| [awesome-skills/code-review-skill](https://github.com/awesome-skills/code-review-skill)（1.7k★） | 1 | 生产级代码审查：20 种语言参考 + 架构审查指南 + 安全审查指南 + 性能审查指南 + 跨领域模式（async/N+1/SQLi/XSS） |
| [tag1consulting/claude-comprehensive-review](https://github.com/tag1consulting/claude-comprehensive-review) | 1 | 综合 PR/MR 审查：17 个静态分析脚本（eslint/ruff/phpstan/semgrep/checkov/trufflehog 等）+ 17 语言 profile |

### engineering（1483）— 微信生态 / 国内支付 / 移动上架（2026-08-16 第四轮）

第四轮扩充聚焦**微信生态、国内支付、移动端上架**三方面，来源：

| 来源 | 数量 | 覆盖 |
|------|------|------|
| [wechatpay-apiv3/wechatpay-skills](https://github.com/wechatpay-apiv3/wechatpay-skills)（官方） | 1 | 微信支付全产品接入（JSAPI/APP/H5/Native/小程序支付/分账/转账/委托代扣/服务商） |
| [alipay/ai](https://github.com/alipay/ai)（官方） | 8 | 支付宝支付全家桶（payment-integration / pay-for-service / pay-for-402 / aipay / 委托代扣 / 钱包认证 / 企业场景 / 支付反馈） |
| [joneqian/claude-skills-suite](https://github.com/joneqian/claude-skills-suite) | 16 | 微信小程序原生开发（WXML/WXSS/WXS）+ tdesign-miniprogram（TDesign 60+ 组件） |
| [tencentcloudbase/cloudbase-skills](https://github.com/tencentcloudbase/cloudbase-skills)（腾讯云官方） | 29 | 云开发全栈（miniprogram-development / auth-wechat-miniprogram / cloudbase-wechat-integration / 云函数 / 数据库 / CloudRun） |
| [laolaoshiren/claude-code-skills-zh](https://github.com/laolaoshiren/claude-code-skills-zh) | 20 | 中文开发者工具链（i18n-helper / zh-docgen / zh-readme / zh-code-reviewer / api-tester / db-migrator 等） |
| [JustinPerea/app-store-review-skill](https://github.com/JustinPerea/app-store-review-skill) | 1 | iOS App Store 提审预检（隐私字符串/图标/entitlement/账号删除/Sign in with Apple） |
| [android/skills](https://github.com/android/skills)（Google 官方） | 22 | Android 官方（android-cli / navigation-3 / Jetpack Compose 迁移 / play-policy-insights / play-billing / r8-analyzer / perfetto） |
| [secondsky/claude-skills](https://github.com/secondsky/claude-skills) | 20 | mobile 全家桶（app-store-deployment / mobile-app-testing / mobile-app-debugging / payment-gateway-integration / PWA / 推送 / i18n） |

### engineering（1514）— 嵌入式开发（2026-08-16 第五轮补充）

嵌入式固件开发专项，覆盖单片机（STM32/ESP32/Arduino/树莓派）、RTOS（FreeRTOS/Zephyr）、通信协议（MQTT/CoAP/BLE/CAN/USB/IP）、裸机 C 规范：

| 来源 | 数量 | 覆盖 |
|------|------|------|
| [travisjneuman/.claude](https://github.com/travisjneuman/.claude) | 4 | embedded-iot（ESP32/STM32/Arduino/树莓派/FreeRTOS/Zephyr/MQTT/BLE）、edge-computing、electron-desktop、tauri-desktop |
| [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills)（11k★） | 1 | embedded-systems（STM32/ESP32/bare-metal/中断处理/DMA/功耗优化） |
| [beriberikix/zephyr-agent-skills](https://github.com/beriberikix/zephyr-agent-skills)（Zephyr 官方社区） | 22 | Zephyr RTOS 全家桶（kernel-basics / kernel-services / devicetree / build-system / board-bringup / connectivity-ble / connectivity-usb-can / iot-protocols / storage / testing-debugging / power-performance / multicore / native-sim 等） |
| [rovinax/embedded-skills](https://github.com/rovinax/embedded-skills) | 6 | 嵌入式 C 规范（cstyle）/ RTOS 设计 / ISR 设计 / 驱动设计 / 架构 / 文档 |

> 附带补齐桌面端缺口：electron-desktop / tauri-desktop（上一轮缺口 #4 桌面应用）。

### engineering（1728）— 游戏开发（2026-08-16 第六轮)

游戏开发全流程——引擎（Godot/Unity/Unreal/Phaser/PixiJS/three.js/Bevy/LÖVE/Pygame/Roblox）、游戏类型、开发学科、工作室流程：

| 来源 | 数量 | 覆盖 |
|------|------|------|
| [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills)（520★） | 68 | **引擎**：godot 14（gdscript/3D/动画/物理/多人/着色器/tilemap）、unity 8（C#/输入/导航/UI）、unreal 6（蓝图/C++/行为树/Niagara）、phaser/pixijs/threejs、bevy-ecs/love2d/pygame/roblox；**学科 13**：game-ai/game-feel/物理调参/关卡设计/程序化生成/着色器/音效/UI/输入/存档；**类型 8**：rpg/fps/平台跳/解谜/roguelike/卡牌/塔防/生存/视觉小说；**工作流 3**：game-jam/prototype-fast/itch/steam 发布 |
| [Donchitos/Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)（23.9k★） | 73 | 游戏工作室全流程：setup-engine / vertical-slice / sprint-plan / sprint-status / milestone-review / release-checklist / launch-checklist / day-one-patch / playtest-report / team-qa / team-release / team-live-ops / team-combat / team-level / team-narrative / team-audio / balance-check / scope-check / gate-check / smoke-check / soak-test / regression-suite / patch-notes |
| [Unity-Technologies/skills](https://github.com/Unity-Technologies/skills)（Unity 官方，254★） | 22 | new-unity-project / unity-cli / ui（uGUI/uITK/IMGUI）/ shader-graph / URP 后处理 / 物理碰撞 / 多人服务 / 语音 / IAP / 本地化 / 音频优化 / 精灵编辑器 |
| [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills)（1.6k★） | 75 | Unity 编辑器自动化全家桶：animator/cinemachine/light/material/shadergraph/terrain/profiler/netcode/scriptableobject/UI Toolkit/xr/urp/yooasset/hybridclr/dotween/unitask/addressables |
| [alexmeckes/godot-claude-skills](https://github.com/alexmeckes/godot-claude-skills) | 5 | godot-scene-design / godot-live-edit / godot-interactive / godot-code-gen / godot-shader |
| [DirtybitGames/unityctl](https://github.com/DirtybitGames/unityctl) | 4 | unity-editor 远程控制 / release / demo-page / plugins |

### engineering（1790）— 前端补强：Vue / Svelte / CSS / Java-Spring（2026-08-16 第七轮）

补齐前端薄弱项（Vue/Svelte/CSS 专项）与 Java 后端（Spring Boot 系）：

| 来源 | 数量 | 覆盖 |
|------|------|------|
| [vinayakkulkarni/vue-nuxt-best-practices](https://github.com/vinayakkulkarni/vue-nuxt-best-practices) + [alexanderop/claude-skill-vue-development](https://github.com/alexanderop/claude-skill-vue-development) | 6 | vue-best-practices / vue-development / nuxt-best-practices / nuxt-seo / nuxt-geo / nuxt-agent-ready |
| [fubits1/svelte-skills](https://github.com/fubits1/svelte-skills) + [spences10/skills](https://github.com/spences10/skills) | 21 | svelte-code-style / svelte-composition / svelte-migration-svelte-5 / svelte-testing / svelte-storybook / svelte-vitest / svelte-playwright / svelte-runes / sveltekit-data-flow / sveltekit-structure 等 |
| [PyModel/css-pro-tips](https://github.com/PyModel/css-pro-tips) + [msrbuilds/animate-css-skill](https://github.com/msrbuilds/animate-css-skill) | 4 | css-pro-tips（Baseline 现代 CSS）/ animate-css / css-nesting / css-subgrid / pixel-perfect / web-design-guidelines |
| [rrezartprebreza/spring-boot-skills](https://github.com/rrezartprebreza/spring-boot-skills)（215★） | 30 | spring-data-jpa / spring-security-jwt / webflux-reactive / spring-cloud-gateway / spring-batch / flyway-migrations / oauth2 / openapi-first / hexagonal / DDD / event-driven / multi-tenancy / MCP server / spring-ai |
| [claudioed/claude-skills](https://github.com/claudioed/claude-skills) | 4 | java-dependency-auditor / java-mutation-test / java17-2-21-migration / spring-bootstrap-optimizer |

### marketing（21）— 营销与增长

| Skill | 来源 |
|-------|------|
| copywriting / content-strategy / ai-seo / cro / pricing / launch / cold-email / analytics / marketing-plan / customer-research / competitor-profiling | coreyhaines31/marketingskills |
| copywriting-prose-creator / copywriting-tone-of-voice-creator / copywriting-hooks / copywriting-cta / linkedin-ghostwriting / substack-ghostwriting / press-release-writer / influence-and-negotiation / training-report / technical-article-writer | samber/cc-skills |

### research（9）— 深度研究

| Skill | 来源 |
|-------|------|
| deep-research-research-*（research-deep/report/add-fields/add-items） | Weizhena/Deep-Research-skills（英文） |
| deep-research-zh-*（research/report/deep/add-fields/add-items） | Weizhena/Deep-Research-skills（中文） |

### testing（406）— 测试全家桶（qaskills.sh 精选）

The Testing Academy（PramodDutta/qaskills，qaskills.sh）的 QA skill 目录，按测试维度覆盖：

| 维度 | 代表 skill |
|------|-----------|
| E2E/浏览器（36） | playwright-e2e / cypress-e2e / selenium-advance-pom / puppeteer-testing / webdriverio-e2e / visual-regression / percy-visual-regression |
| API/契约（29） | api-fuzzing / api-security-testing / api-contract-validator / contract-testing-pact / graphql-testing / grpc-testing / postman-api / openapi-test-generation |
| 性能/负载（19） | k6-performance / jmeter-load / locust-load-testing / artillery-load / gatling-performance / lighthouse-performance / stress-testing-patterns |
| 安全（24） | owasp-security / zap-security-scanner / xss-testing-patterns / sql-injection-testing / jwt-security-testing / oauth-security-testing / afl-fuzzing / burpsuite-security |
| 单元/方法（20） | jest-unit / vitest / pytest-best-practices / mutation-testing / property-based-testing / snapshot-testing / test-driven-development |
| 可访问性（8） | accessibility-a11y-enhanced / wcag-accessibility-testing / axe-accessibility / pa11y-accessibility-ci |
| 移动（11） | appium-mobile / detox-mobile / espresso-android / xcuitest-ios / maestro-mobile / mobile-performance-testing |
| LLM/AI（17） | llm-output-testing / llm-security-testing / prompt-testing / ragas-rag-evaluation / deepeval-llm-evaluation / vibe-testing / ai-agent-eval |
| 数据/DB（16） | database-migration-testing / redis-testing / mongodb-testing / kafka-event-driven-testing / test-data-generation / faker-test-data |
| CI/流程（25） | cicd-pipeline / quality-gates-ci / test-plan-generation / test-strategy-design / regression-test-selection / smoke-test-suite / flaky-test-doctor |

其余 ~200 个覆盖：混沌工程（chaos-engineering-advanced）、契约优先（contract-first-testing）、测试数据（test-data-anonymization）、报告（allure-report-generator）、测试管理（testrail-test-management）、以及各语言框架（go-testing/rust-testing/spring-boot-testing/django-testing/fastapi-testing 等）。

## 许可与致谢

本仓库是**第三方开源 skill 的精选合集**，每个 skill 保留其原始仓库的 license。来源：

- [obra/superpowers](https://github.com/obra/superpowers)（272k★）
- [affaan-m/ECC](https://github.com/affaan-m/ECC)（240k★）
- [mattpocock/skills](https://github.com/mattpocock/skills)（218k★）
- [anthropics/skills](https://github.com/anthropics/skills)（169k★）
- [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)（98k★）
- [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)（87k★）
- [mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill)（58k★）
- [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)（46k★）
- [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills)（44k★）
- [PramodDutta/qaskills](https://github.com/PramodDutta/qaskills)（QA 测试 skill 目录，qaskills.sh）
- [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)（30k★）
- [Weizhena/Deep-Research-skills](https://github.com/Weizhena/Deep-Research-skills)（1.9k★）
- [samber/cc-skills](https://github.com/samber/cc-skills)
- [wshobson/agents](https://github.com/wshobson/agents)（39k★）
- [sickn33/agentic-awesome-skills](https://github.com/sickn33/agentic-awesome-skills)（45k★）
- [wechatpay-apiv3/wechatpay-skills](https://github.com/wechatpay-apiv3/wechatpay-skills)（微信支付官方）
- [alipay/ai](https://github.com/alipay/ai)（支付宝官方）
- [tencentcloudbase/cloudbase-skills](https://github.com/tencentcloudbase/cloudbase-skills)（腾讯云官方）
- [android/skills](https://github.com/android/skills)（Google 官方，6.8k★）
- [joneqian/claude-skills-suite](https://github.com/joneqian/claude-skills-suite)
- [laolaoshiren/claude-code-skills-zh](https://github.com/laolaoshiren/claude-code-skills-zh)（764★）
- [JustinPerea/app-store-review-skill](https://github.com/JustinPerea/app-store-review-skill)
- [secondsky/claude-skills](https://github.com/secondsky/claude-skills)（206★）
- [travisjneuman/.claude](https://github.com/travisjneuman/.claude)（127 skills）
- [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills)（11k★）
- [beriberikix/zephyr-agent-skills](https://github.com/beriberikix/zephyr-agent-skills)（Zephyr RTOS）
- [rovinax/embedded-skills](https://github.com/rovinax/embedded-skills)
- [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills)（520★）
- [Donchitos/Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)（23.9k★）
- [Unity-Technologies/skills](https://github.com/Unity-Technologies/skills)（Unity 官方）
- [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills)（1.6k★）
- [alexmeckes/godot-claude-skills](https://github.com/alexmeckes/godot-claude-skills)
- [DirtybitGames/unityctl](https://github.com/DirtybitGames/unityctl)
- [vinayakkulkarni/vue-nuxt-best-practices](https://github.com/vinayakkulkarni/vue-nuxt-best-practices)
- [alexanderop/claude-skill-vue-development](https://github.com/alexanderop/claude-skill-vue-development)
- [fubits1/svelte-skills](https://github.com/fubits1/svelte-skills)
- [spences10/skills](https://github.com/spences10/skills)
- [PyModel/css-pro-tips](https://github.com/PyModel/css-pro-tips)
- [msrbuilds/animate-css-skill](https://github.com/msrbuilds/animate-css-skill)
- [rrezartprebreza/spring-boot-skills](https://github.com/rrezartprebreza/spring-boot-skills)（215★）
- [claudioed/claude-skills](https://github.com/claudioed/claude-skills)
- [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills)（24k★）
- [awesome-skills/code-review-skill](https://github.com/awesome-skills/code-review-skill)（1.7k★）
- [tag1consulting/claude-comprehensive-review](https://github.com/tag1consulting/claude-comprehensive-review)
- [am-will/swarms](https://github.com/am-will/swarms)
- [shinpr/sub-agents-skills](https://github.com/shinpr/sub-agents-skills)
- [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)

如需商用，请查阅各原始仓库的具体 license 条款。

## 维护

- 新增 skill：放入 `skills/<category>/<name>/`（含 SKILL.md 及引用文件），更新本 README 清单
- 更新流程：参照 `third-party-skill-install`（发现→评估→克隆→探测→安装→验证）
- 安全要求：**本仓库禁止出现**内网 IP、域名、凭据、API key
