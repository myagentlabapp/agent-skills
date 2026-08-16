# GitLab external_url https 强制重定向修复

## 症状
浏览器访问 `http://域名:端口/` 自动跳转 `https://域名:端口/...` 然后打不开（证书错误/TLS 失败）。

## 根因
- gitlab.rb 里 `external_url 'https://gitlab.xxx'` → GitLab nginx 把所有 http 根路径请求 302 到 https 版本
- 端口映射背后是容器 80（HTTP），https 访问 5080 端口做 TLS 握手失败
- 细节：`/users/sign_in` 路径 http 直连返回 200，只有根路径 `/` 会 302——可先绕过根路径应急

## 诊断证据
```
curl -sI http://127.0.0.1:5080/
→ HTTP/1.1 302 Found
→ Location: https://127.0.0.1:5080/users/sign_in   ← https 开头就是 external_url 配置导致的
```
确认配置：`docker exec <容器> grep external_url /etc/gitlab/gitlab.rb`
看端口映射：`docker ps --format "{{.Names}}\t{{.Ports}}"`（5080->80 是 HTTP，5443->443 是 HTTPS）

## 修复步骤
```bash
# 1. 备份
docker exec gitlab cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.bak-$(date +%Y%m%d)
# 2. 替换
docker exec gitlab sed -i "s|external_url 'https://gitlab.xxx'|external_url 'http://域名:端口'|" /etc/gitlab/gitlab.rb
# 3. reconfigure（2-5 分钟，直接跑会超时 → 后台 + 日志轮询）
nohup docker exec gitlab gitlab-ctl reconfigure > /tmp/gitlab-reconfig.log 2>&1 &
# 轮询：tail /tmp/gitlab-reconfig.log，看到 "gitlab Reconfigured!" 即完成
```

## 验证
```
curl -sI http://127.0.0.1:5080/ | grep -iE "^(HTTP|Location)"
→ Location: http://127.0.0.1:5080/users/sign_in   ← http 开头即修复成功
```
再浏览器访问 `http://域名:端口/` 应正常跳转登录页。

## 坑
- **reconfigure 2-5 分钟**，ssh_exec/工具默认超时 → 必须 nohup 后台跑 + 轮询日志文件
- **reconfigure 期间服务 502 Bad Gateway 属正常**（nginx 重建中），别当成故障
- **docker exec 不经过 shell**：`ls /etc/gitlab/gitlab.rb.bak-*` 通配符不展开报 No such file，要 `docker exec gitlab ls /etc/gitlab/ | grep bak` 验证备份
- 改 external_url 影响所有链接生成（clone URL 变 `http://域名:端口/xxx.git`）
- 日志结尾若出现 "Infra Phase complete... gitlab Reconfigured!" 才是成功；"already initialized constant" 是 Ruby 警告，可忽略
