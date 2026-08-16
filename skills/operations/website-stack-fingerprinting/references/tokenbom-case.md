# tokenbom.com 案例：判定「自研非开源」

问题：tokenbom.com（闲置 AI API 额度共享市场）是不是基于开源项目？结论：**自研**。

## 证据链

1. **HTML 壳**：Vite + React SPA（`/assets/index-*.js` + `<div id="root">`）。
   - `/pricing` `/docs` 等路由带 `<noscript>` SEO 预渲染内容 → 非纯 CSR
   - meta description: "闲置 AI API 额度共享市场：提供者接入用不完的额度赚积分，开发者通过 OpenAI 兼容端点按需调用"

2. **JS bundle 全库 grep 结果**：
   - GitHub 链接：0 命中
   - 许可证/版权/ICP/备案/Powered by：0 命中
   - 已知开源 UI 框架（antd/arco/mui/tailwind/shadcn 等）：0 命中
   - 已知开源 AI 中转（one-api/new-api/sub2api/cockroachai/dify/open-webui/LobeChat）：0 命中
   - `vite` 出现 118 次 = 构建工具，不算框架特征
   → 自研组件，无开源模板痕迹

3. **robots.txt** 第一行注释 `# SubShare robots.txt` → 泄露项目代号 **SubShare**。
   - GitHub 搜 `SubShare`：全部无关（2018/2023 的 Ruby 文件同步工具、空描述仓库）→ 代号对不上任何开源项目

4. **OpenAI 兼容端点 `/v1/models`**（无需鉴权）返回：
   - `owned_by: "tokenbom"` + `capabilities{...}` + `architecture{...}` 字段
   - 该结构不匹配 one-api / new-api / sub2api / cockroachai 任何一家的返回 → 自研网关
   - 这是"网关非开源"的决定性证据

5. **佐证**：server `nginx/1.24.0 (Ubuntu)` 自托管；robots 显示有 `/admin /v1/ /dashboard /keys /credits /invites /virtual-keys /flash-sales` 全套商业功能（邀请返利、闪购、虚拟 key、积分系统）。

## 产品面速写（对智体工坊有参考价值）

- 商业模式：Provider 接入闲置额度赚积分；开发者按需调用；供给随市场变化、不承诺 SLA
- 功能：积分体系、邀请返利（含违规追回）、闪购、虚拟 key、OpenAI/Anthropic/Gemini 三套兼容协议
- 运营形态：全新、无公开开源、无版权/备案信息（可能是海外/个人运营）
