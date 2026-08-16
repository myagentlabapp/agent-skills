---
name: public-network-diagnostics
description: 公网可达性排查与 DDNS 配置——让内网服务通过公网/域名可访问。覆盖 Cloudflare 灰云 A 记录 DDNS（动态公网 IP）、公网端口连通性检测（check-host.net）、DMZ/运营商 NAT 判断、GitLab external_url https 重定向修复。用户问"为什么公网/域名访问不了"或要做"DDNS/公网直连"时使用。
tags: [ddns, cloudflare, dns, network, public-access, dmz, gitlab]
---

# 公网可达性排查与 DDNS

## 触发场景
- 用户问"为什么 http://域名:端口 访问不了"
- 要做 DDNS（动态公网 IP → 域名），或让内网服务公网直连
- 域名解析正常但公网访问失败，需要分层排查

## 排查方法论（按层，先分清楚故障在哪层）

1. **DNS 解析层**：域名 → IP 对不对（python `socket.gethostbyname` 或 dig @1.1.1.1）
2. **公网路由层**：公网 IP 从外部是否可达（check-host.net API，见 references/check-host-net-api.md）
3. **入口转发层**：DMZ/端口映射是否生效（**这条最容易漏**——2026-07-31 案例：所有端口全球超时，根因只是 DMZ 没开，不是网络问题）
4. **服务层**：本地端口服务是否活着（`curl 127.0.0.1:端口`，看 302/200 和响应头判断是什么服务）

## 关键盲点（全部实测踩过）

- **内网 hairpin 测试不可靠**：内网机器 curl 自己公网 IP 超时 ≠ 公网不可达（路由器 NAT 回流支持问题）。DMZ 开启后有的路由器 hairpin 会通，但**不通不能下任何结论**。
- **免费 CORS/HTTP 代理不可靠**：allorigins / corsproxy.io / codetabs 各有各的错误码（allorigins 的 500 是它自己的错误响应，不是目标服务的响应）。不要用它们当连通性证据。
- **check-host.net 全是海外节点**（英/美/伊朗/哈萨克斯坦等）：海外全超时 ≠ 国内不可达（国内宽带对海外入站路由可能不通，反之亦然）。海外超时时优先怀疑 DMZ 没开，**让用户用 IP 直连实测确认**，不要直接下"CGNAT/无公网IP"结论。
- **真正的 CGNAT 判断依据**：路由器 WAN 口 IP 是 100.64.x.x / 10.x.x.x 私有段，或 Wiki 历史记录（如花生壳页面写"IPv4 无公网 IP"）。不要仅凭出口 IP 段猜。
- **用户实测能访问是权威结论**，优先于任何代理/节点测试结果。

## 验证纪律（用户明确要求）

- 修完必须从**用户视角**验证：公网真实路径 + 真浏览器。
- **工具不可用就排查修复，不要绕过/模拟**（2026-07-31 纠正：browser 工具报 Chrome not found 时，正确做法是装好 agent-browser + Chrome，而不是用 curl -L 模拟浏览器交差）。
- 本机真浏览器安装：`npm install -g agent-browser`（国内加 `--registry=https://registry.npmmirror.com`）→ `agent-browser install`（Chrome for Testing，约 184MB，装到 ~/.agent-browser/browsers/）。root 容器无需 sudo。

## DDNS 配置流程（Cloudflare 灰云，2026-07-31 实测跑通）

1. 确认：动态公网 IP + DMZ 已指向目标机（目标机监听 0.0.0.0:端口）
2. Cloudflare 建 A 记录（灰云 = DNS-only，非 HTTP 端口也能直连；橙云 proxied=true 只代理 80/443）：
   `POST /zones/{zone}/dns_records` `{"type":"A","name":"域名","content":"出口IP","proxied":false,"ttl":120}`
3. 更新脚本部署在 **DMZ 目标机**（出口 IP 最准）：
   - `IP=$(curl -s ifconfig.me)`，对比 last_ip 文件，变了才 PUT 记录（幂等，避免每 5 分钟刷 API）
   - `PUT /zones/{zone}/dns_records/{rec_id}` 更新 content
   - Cloudflare API token 见 Wiki `ops/cloudflare-api`（base64 存储，`base64 -d` 解码）
4. cron 追加（保留原有条目）：`(crontab -l 2>/dev/null; echo "*/5 * * * * /path/update-ddns.sh >> /path/ddns.log 2>&1") | crontab -`
5. 验证：手动跑一次（应输出"IP 更新为 X"），再跑一次（应静默 exit 0）

## 服务暴露后常见坑

### GitLab 强制跳 https 打不开
- 现象：浏览器访问 `http://域名:端口/` 自动跳 `https://域名:端口` 然后失败
- 原因：gitlab.rb `external_url 'https://xxx'` → nginx 把 http 根路径 302 到 https；而映射端口背后是容器 80（HTTP），https 握手失败
- 修复：备份 gitlab.rb → sed 替换 external_url 为 `http://域名:端口` → reconfigure。详见 references/gitlab-https-redirect-fix.md
- 注意：GitLab 登录页 `/users/sign_in` 本身 http 直连返回 200，只有根路径 `/` 会 302——绕过根路径可先应急

## 支持文件
- references/check-host-net-api.md —— check-host.net 公网端口检测 API 用法（含节点局限）
- references/gitlab-https-redirect-fix.md —— GitLab external_url 修改 + reconfigure 完整流程
