---
name: website-stack-fingerprinting
description: 判断网站是否基于开源项目或用什么技术栈。触发词：XX 网站是开源项目吗、XX 用什么技术栈、竞品用的什么搭的。
---

# 网站技术栈指纹识别（是否基于开源项目）

判断一个网站是自研还是基于某个开源项目（尤其 AI API 中转/网关类：one-api / new-api / sub2api / cockroachai / LobeChat 等），以及大致技术栈。纯外部侦察，无需登录。

## 流程

1. **抓 HTML**：`curl -sL -A "Mozilla/5.0..." https://site/`
   - 看 `<meta name="description">` 和 OG 标签确定产品定位
   - 看 bundle 命名特征：`/assets/index-*.js` + `<div id="root">` = Vite/React SPA
   - 有 `<noscript>` 内容 = 做了 SEO 预渲染/SSG（说明不是纯客户端渲染）
   - SPA 所有路由返回同一个壳，要额外抓几个代表性路径（/pricing /docs /about）确认

2. **下载 JS bundle 并 grep 特征**（关键步骤）：
   ```
   curl -sL https://site/assets/<main-js> -o main.js
   curl -sL https://site/assets/<vendor-js> -o vendor.js
   ```
   grep 关键词，命中次数决定结论：
   - **GitHub 链接**：`https://github\.com/[A-Za-z0-9_./-]*`
   - **许可证/版权**：`MIT license|GPL|Apache[- ]2\.0|copyright|版权|ICP|备案|Powered by|powered by`
   - **已知开源 UI 框架**：`antd|ant-design|@arco-design|element-plus|@mui|@headlessui|tailwind|shadcn`
   - **已知开源 AI 中转项目**：`one-api|new-api|sub2api|cockroachai|dify|open-webui|LobeChat`
   - 全部 0 命中 = 自研/私有组件，大概率不是开源项目改的

3. **看 robots.txt**（最容易漏、最有信息量的步骤）：
   - 注释行常写项目代号！如 `# SubShare robots.txt` → 代号拿去 GitHub 搜
   - `Disallow: /admin /api/ /v1/` 说明有管理后台 + OpenAI 兼容网关，值得探
   - 可能泄露路由结构（/dashboard /keys /credits /invites 等）

4. **探测 OpenAI 兼容端点**：`curl https://site/v1/models`（通常无需鉴权）
   - 看返回结构：`owned_by` 字段、`capabilities`/`architecture` 字段
   - one-api/new-api/sub2api/cockroachai 各有特征返回结构；对不上 = 自研网关
   - 这是判断网关是否开源的**决定性证据**

5. **GitHub API 搜代号**：`https://api.github.com/search/repositories?q=<代号>`，看 description/language/创建时间判断是否真相关（同名仓库常是无关旧项目，要核验）。

6. **其他佐证**：响应头（server: nginx 版本、CSP 配置）、sitemap.xml（公开页面清单）、favicon（有无版权）。

## Pitfalls

- **SPA 所有路径返回同一 HTML 壳**，不能只抓首页就下结论；不同路由抓一下，看 SEO 预渲染内容
- **robots.txt 注释行泄露内部项目代号**是最强线索，别跳过
- 前端无开源特征 ≠ 网关也自研；反之亦然，要两端都查
- GitHub 同名词条要核验创建时间/语言/描述，同名仓库 90% 是无关项目
- bundle 里出现 `vite` 字眼只是构建工具，不算开源框架特征
- 底层用了 React/Vite/nginx 等生态库 ≠ 平台本身是开源项目——回答用户时要把"基础设施开源"和"平台自研"区分开

## 参考

- `references/tokenbom-case.md` — tokenbom.com 实例：完整判定"自研非开源"的证据链（robots 泄露代号 SubShare、bundle 零开源特征、/v1/models 自定义结构）
