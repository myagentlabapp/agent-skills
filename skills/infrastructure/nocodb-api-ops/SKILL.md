---
name: nocodb-api-ops
description: 自建 NocoDB（Airtable 开源版）数据平台的部署与 REST API 调用——批量插入必须用裸数组（{"records":[...]}包装每批只插1条）、单批上限100、API Token 认证（登录JWT不可用）、按主键去重导入。触发词：NocoDB、导入数据到NocoDB、nocodb API、数据平台。
---

# NocoDB 数据平台 API 操作

## 是什么
NocoDB = Airtable 开源版，Docker 单容器，Web 表格 UI + REST API。本组织用它做 QQ 群成员/好友数据总库（119:18080，Base「QQ成员库」）。

## 部署

```bash
docker run -d --name nocodb -p 18080:8080 -v /home/yy/nocodb-data:/usr/app/data nocodb/nocodb:latest
```

- 首次启动慢（数据库迁移），日志出现 "completed configure" 后仍需等 web 返回 200
- 数据持久化在挂载目录，**备份该目录 = 备份全部数据**
- 国内网络：docker.io 直连超时，用 `docker.1ms.run` 加速源或从本机 `docker save | ssh docker load` 传镜像

## 认证（关键）

- **登录接口返回的 JWT 不能调 API**（实测 `/api/v1/auth/user/me` 返回 guest，v2 接口 401）——必须在 WebUI 生成 API Token：头像菜单 → API Tokens → Create new token（**只显示一次**，立即保存）
- 请求头：`xc-token: <token>`

## ⚠️ 批量插入（最大的坑，实测 2026-08）

- **必须用裸数组**：`POST /api/v2/tables/{tableId}/records`，body = `[{...},{...}]`（不带外层包装）
- **不要用 `{"records":[...]}` 包装**——那样每批只插 1 条！表现是"接口 200 导入成功"但 totalRows 没涨，静默丢数据
- **单批上限 100 条**，超出报 `ERR_MAX_PAYLOAD_LIMIT_EXCEEDED`（插入和删除都限 100）
- 验证导入是否真的进去：查 `GET .../records?limit=1` 的 `pageInfo.totalRows`

## 其他 API 要点

| 操作 | 端点 / 格式 |
|------|-------------|
| 读记录 | `GET /api/v2/tables/{id}/records?limit=1000&offset=N`（分页循环拿全量） |
| 筛选 | `?where=(字段,eq,值)`；字段名是中文要 URL 编码，否则 UnicodeEncodeError |
| 删除 | `DELETE /api/v2/tables/{id}/records` body = `[{"Id":N},...]`（裸数组对象；纯 ID 数组报 "Primary key is required"），100/批 |
| 建表 | `POST /api/v2/meta/bases/{baseId}/tables` `{title, columns:[{title, uidt}]}` |
| 找 ID | `GET /api/v2/meta/bases` → base；`/api/v2/meta/bases/{baseId}/tables` → table |

- **表默认没有唯一约束**：同一主键重复插入会产生重复行。去重必须在脚本里做（先拉已有主键集合，跳过重复），别指望数据库挡
- 建表时若需要唯一，可在 UI 给列开唯一约束（API 建的列默认没有）

## 大数据导入的运维坑

- ssh_exec 工具约 60s 超时：大导入用 nohup 后台跑 + 定期 `tail` 日志轮询
- **"超时"的 nohup 进程其实还在跑**——重跑导入前先 `pgrep -f <脚本名>` 查残留，否则两个进程双写重复数据（本次踩过：好友表双写 9,595 条，靠按 QQ 号查重删掉 4,572 条）
- `pkill -f <模式>` 会杀掉自己所在的 ssh 会话（命令行里含匹配串）——改用 `pgrep -f` 拿 PID 再 kill，或让模式不出现在自己命令行中

## 脚本

- `scripts/nocodb_import.py` — 通用 CSV → NocoDB 导入（裸数组 100/批，`--key` 指定主键列自动去重跳过已有）

## 参考

- Base/Table ID、API token、账号密码：Wiki `departments/infrastructure/docs/ops/nocodb-credentials`
- 使用教程（Web UI 操作 + curl 示例）：Wiki `services/nocodb-guide`
