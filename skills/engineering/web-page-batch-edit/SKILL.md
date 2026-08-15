---
name: web-page-batch-edit
description: "Batch-edit static pages: cache-bust, unify nav, verify all."
version: 0.1.0
author: Hermes
license: MIT
metadata:
  hermes:
    tags: [Frontend, Static, HTML, Cache, Navigation, Verification]
---

# 静态网页批量修改与缓存失效

批量改多个静态 HTML/CSS 文件（统一导航、改样式、换文案）后，让改动真正生效并在所有页面验证。覆盖三个最容易翻车的环节：批量脚本的写盘坑、浏览器/代理缓存失效、全页面（含登录态）验证纪律。

## When to Use

- 多个页面要统一导航/样式/文案（「这些页面风格能统一吗」「为什么导航不一样」）
- 改了 CSS/JS 但浏览器里看不到效果（样式没生效/还是旧的）
- 前端改动后需要证明「所有页面都改到了」而不是抽查一个
- 给多个页面加统一的登录态感知组件（未登录不显示受限入口）

## Prerequisites

- 静态文件在远程机器（如 `/mnt/storage/quota-marketplace/portal/frontend/`），用 `paramiko` 的 sftp 读写
- Cloudflare API token（清缓存用，见 Wiki `ops/cloudflare-api`）
- 浏览器验证用 playwright 直连 browserless（方法见 `headless-browser-automation` skill）

## How to Run

1. 写批量替换脚本（sftp 拉→改→**写回本地文件**→sftp 传）
2. CSS/JS 引用 bump 版本号 `?v=N`
3. 清 CF 缓存（`purge_cache` purge_everything）
4. playwright 逐页验证（含登录态注入 token）

## Quick Reference

```bash
# CF 清缓存（Python，token 从 Wiki ops/cloudflare-api 拿）
cf_req("POST", f"/zones/{ZONE_ID}/purge_cache", {"purge_everything": True})

# 浏览器强刷绕过缓存
location.href = url + '?r=' + Date.now()
# 查浏览器实际加载的 CSS 规则（区分缓存 vs 新文件）
for (const sheet of document.styleSheets) { for (const r of sheet.cssRules) { if (r.selectorText === '.x') return r.cssText; } }
# 验证 CSS 文件本身内容（绕过页面加载的缓存版本）
fetch(url + '?probe=' + Date.now()).then(r => r.text())
```

## Procedure

### 1. 批量替换脚本（写盘坑）

```python
# ⚠️ 铁律：sftp.put 上传的是磁盘文件，不是内存变量！
# 改完 content 后必须先写回本地文件，再 sftp.put，否则上传的是旧文件
sftp.get(remote, local)
content = open(local, encoding='utf-8').read()
content = do_replace(content)          # 改内存
open(local, 'w', encoding='utf-8').write(content)   # ← 必须写盘
sftp.put(local, remote)                # ← 才传新内容
```

- 正则匹配 `<nav ...>...</nav>` 用 `re.compile(r'<nav[^>]*>.*?</nav>', re.S)`——但**嵌套 brand 结构可能匹配不全**，替换后用 `search_files` 验证每个页面真的改了（如 `search_files` pattern `app-nav` 应命中所有页面）
- 替换完成后**逐个验证**：脚本打印「已替换」不代表文件真变了（见上面的内存/磁盘坑）

### 2. 缓存失效（样式不生效的标准排查）

症状：改了 style.css，浏览器 getComputedStyle 还是旧值，但 `curl`/`fetch` 带新参数拿到的文件是新内容。

排查顺序：
1. `getComputedStyle(el).position` 看当前生效值
2. 遍历 `document.styleSheets` 找 selector 的实际 `cssText`——**这决定浏览器加载的是哪个版本**
3. `fetch(url + '?probe=' + Date.now())` 拿服务器最新文件对比

修复：
1. HTML 里 link/script 引用 bump 版本号：`assets/style.css?v=2`（**所有页面都要改**，脚本批量做）
2. CF 清缓存：`POST /zones/{id}/purge_cache {"purge_everything": True}`
3. 浏览器硬刷新 `location.reload(true)` 或带 `?r=Date.now()` 重新导航

### 3. 统一登录态感知导航（nav.js 模式）

写一个共享组件 `nav.js`，所有页面 `<nav><div id="app-nav"></div></nav>` + 引入脚本：

- 读 `localStorage.getItem("portal_token")` + `portal_user` 判断登录态
- 未登录：公共项（首页/模型市场/快速开始/定价）+ 「登录/注册」按钮
- 已登录：公共项 + 受限项（收益看板/Key 管理）+ 用户名 + 退出
- 退出清 localStorage → 跳主页

好处：改导航只改一个文件；未登录不暴露受限入口。

### 4. 全页面验证（含登录态）

- 公开页面直接 goto 验证；**需要登录的页面**：先 `page.evaluate` 调登录 API 拿 token → 新 context + `add_init_script` 注入 `localStorage.setItem('portal_token', tok)` → 再 goto（否则 ensureAuth 重定向回登录页，测不到导航）
- `ctx.add_init_script(script, token)` **不支持第二参数**——token 用 `%` 拼进脚本字符串
- 逐页记录：URL、导航项、居中 offset（`getBoundingClientRect` 中心 vs `document.documentElement.clientWidth/2`）、页面标题
- 登录态页面和未登录态页面**分别验证**（导航项应该不同）
- 移动端单独 context：`browser.new_context(viewport={"width": 375, "height": 667})`

## Pitfalls

- **sftp.put 上传磁盘旧文件**（最常见）：改的是内存 content，没写回本地文件就 put → 远程没变，脚本还打印「已替换」。必须 `open(local,'w').write(content)` 再 `sftp.put(local, remote)`
- **正则匹配嵌套 HTML 块**：`<nav[^>]*>.*?</nav>` 对含嵌套 `<span>` 的 brand 结构可能匹配不全或匹配错位；替换后 grep 验证每个文件
- **CSS 缓存**：getComputedStyle 旧值 + fetch 新值 = 浏览器/代理缓存旧 CSS。HTML link 无版本号是根因
- **`window.innerWidth` 含滚动条**（15px）——测居中偏移必须用 `document.documentElement.clientWidth`，否则得到 -7 假偏差（详见 `headless-browser-automation`）
- **用户浏览器缓存**：即使线上已修好，用户看到的可能还是旧版——告知硬刷新 `Ctrl+Shift+R` 或无痕窗口
- **`docker exec conhub-mcp python3` 传脚本**：sftp 写容器卷路径会 EACCES，用「写 111 /tmp → `docker cp` 进容器 → docker exec 执行」

## Verification

```bash
# 所有页面导航项一致 + 居中（用 playwright 直连 browserless）
for each page: links = nav.querySelectorAll('.nav-links a').map(a => a.textContent.trim())
offset = (links.getBoundingClientRect().left + width/2) - document.documentElement.clientWidth/2
# offset 必须为 0，且所有页面 links 数组一致（未登录 4 项 / 登录后 6 项）
```
