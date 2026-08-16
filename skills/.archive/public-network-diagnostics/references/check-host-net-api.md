# check-host.net API —— 公网端口/连通性检测

从公网多节点检测目标主机 TCP 端口可达性。比免费 CORS 代理可靠得多，是可用的公网视角证据。

## 用法（Python）

```python
import json, time, urllib.request

UA = {"Accept": "application/json",
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) Chrome/120.0"}  # 必须有 UA，否则 403

def check_port(host_port, max_nodes=3):
    # 1. 发起检测
    url = f"https://check-host.net/check-tcp?host={host_port}&max_nodes={max_nodes}"
    req = urllib.request.Request(url, method="POST", headers=UA)
    data = json.loads(urllib.request.urlopen(req, timeout=20).read())
    rid = data.get("request_id")
    # 2. 等待几秒后取结果
    time.sleep(5)
    req2 = urllib.request.Request(f"https://check-host.net/check-result/{rid}", headers=UA)
    res = json.loads(urllib.request.urlopen(req2, timeout=20).read())
    for node, info in (res or {}).items():
        for t in info or []:
            if isinstance(t, dict) and "error" in t:
                print(f"  {node}: ❌ {t['error']}")          # Connection timed out = 不可达
            else:
                print(f"  {node}: ✅ 可达 {t}")              # 有 address/time = TCP 连通
```

- 其他端点：`/check-ping?host=`（ICMP）、`/check-http?host=http://...`（HTTP）
- `max_nodes` 控制节点数，默认 3

## ⚠️ 节点局限（2026-07-31 误判教训）

- **节点全部在海外**（uk/us/ir/kz/at/fr/id/pl/in/ca/cy/sg 等），没有国内节点。
- 海外全超时 ≠ 国内不可达：国内宽带对海外入站路由可能不通，国内用户访问可能完全正常。
- 反之海外通也不代表国内一定通。
- **正确用法**：海外全超时时，优先排查 DMZ 是否开启、让用户 IP 直连实测；不要据此断言"无公网 IP / CGNAT"。

## 真实案例（2026-07-31）

- DMZ 未开时：所有端口（80/443/5080/9100/22）海外节点全超时 → 误判"公网不可达，可能 CGNAT"
- 用户开 DMZ 后：IP 直连可访问，check-host 节点（ca/cy/sg）全部连通（0.3-0.4s）
- 结论：根因是 DMZ 没开，不是网络类型问题
