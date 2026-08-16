# TokenBom 额度市场 — 文档链清单（2026-08-16 审计后）

需求→设计→架构→测试→上线全链路的文档归属。审计后已补测试一环并互相链接成闭环。

## 文档链现状

| 环节 | 文档路径 | 说明 |
|------|---------|------|
| 需求 | `departments/infrastructure/docs/plans/tokenbom-style-marketplace` §1-3/§6/§7 | 背景/目标/商业模式/边界/风控/合规 |
| 设计 | marketplace §3.4/§4/§5 + poc §2 | 买卖流程/提现表/打款SOP/模块规格 |
| 架构 | marketplace §8（8.1总览~8.8技术评审） | 组件/数据流/安全/部署 |
| 测试 | `departments/infrastructure/docs/plans/tokenbom-test-plan`（**2026-08-16 新建**） | E2E 48步闭环/修复回归/验收标准 |
| 上线 | poc §5/§12 后台 + poc §12 工程进度追踪 | 执行状态/公网入口/凭据快照/git链/环境坑 |

## 互链方式

每页顶部加 `> **文档链**：[需求/设计/架构] ← [本页] → [测试/验收]` 块；相关文档表列兄弟页。

## 测试文档核心口径（tokenbom-test-plan）

- E2E 48 步覆盖：公开端点/注册(PBKDF2+并发409)/登录/提现兑换校验/挂key(Fernet加密)/记账幂等/log_id/管理打款/越权矩阵(401×2+403+会话隔离)/双账号打通。
- 已修 bug 回归断言：并发注册 500→409；非 admin JWT 401→403 权限不足；长用户名>20→400（原误写 12，实测网关 max=20）。
- 回归纪律：修复后重跑先更新过时断言，别把"断言没跟上修复"当残留 bug。
- 库区分：活库 `/mnt/storage/quota-marketplace/data/marketplace.db`；`portal/data/` 下是 stale/dev。
- 网关 429 限流（登录频控空 body → `_gw_login` Expecting value）：重启 `quota-marketplace-gateway` 容器清限流，非代码缺陷。

## 验收门禁（上线前跑）

全业务闭环 E2E ≥47/48 PASS 无 real-bug；关键路径功能级真实调用；越权矩阵 4 项；双账号打通+统一账号改密同步；portal/网关/前端三容器 Up + /api/status gateway_reachable=true。
