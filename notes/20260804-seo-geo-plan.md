# tiwenzhe.com SEO + GEO 技术方案（2026-08-04）

> 分析范围：线上站点 https://tiwenzhe.com + 本仓（Quartz 4 + Cloudflare Pages）。
> 执行方：标注 [codex] 的由 codex 改代码；标注 [Eric] 的需要人工操作账号/后台。
>
> **已确认（2026-08-04 Eric 拍板）**：本轮实施 P0 + P1 全部 [codex] 项；
> 另加一项：**移除右栏 Graph（关系图谱）组件**（原 P2-3 选项 A，减 ~400KB JS）；
> 首页 title 定稿：**「聪明的提问者｜Math Academy 中文指南与 AI 时代数学学习」**。
> P2 其余项本轮不做。

## 现状盘点（已经做对的，不要动）

- 每页 canonical、OG/Twitter 卡片、自动生成 OG 图（webp ~30KB）
- JSON-LD：文章页 BlogPosting（含 author/publisher/日期），首页 WebSite
- robots.txt 全开放 + sitemap.xml；GPTBot / ClaudeBot / PerplexityBot / Baiduspider 实测均可访问（200）
- www.tiwenzhe.com 与旧域名 poisemath.com 均 301 → apex；trailing slash 308 规范化
- llms.txt 已存在（但内容过期，见 P0-2）；RSS 在 /index.xml
- 49 篇文章 frontmatter 全部有 title/description/tags/slug/date
- 页面有面包屑（视觉）、作者署名、backlinks、标签；`<html lang>` 存在
- 字体走系统回退（无 webfont 下载），页面 HTML 仅 ~40KB

## P0 — 高影响，先做

### P0-1. 搜索引擎收录与站长工具 [Eric 为主]

**问题**：搜索中查不到 tiwenzhe.com 的收录痕迹；页面无 GSC/Bing/百度验证 meta。域名 2026 年才从 poisemath.com 迁来，不主动提交收录会很慢。
**做法**：

- [Eric] Google Search Console 验证（推荐 DNS TXT，Cloudflare 里加一条即可），提交 sitemap.xml；在 GSC 检查旧域名迁移状态
- [Eric] Bing Webmaster Tools 验证 + 提交 sitemap（Bing 索引同时供给 ChatGPT Search / Copilot，这是 GEO 的直接入口）
- [codex] 新增 IndexNow 支持：生成 key 文件 emitter + 构建后 ping Bing IndexNow API 的脚本（Cloudflare Pages 部署 hook 或 CI 步骤），新文章发布即刻通知 Bing 系
- [Eric，可选] 百度站长平台普通收录提交。预期管理：无 ICP 备案 + Cloudflare 海外节点，百度权重天然受限，不值得重投入——国内分发主渠道仍是公众号

### P0-2. llms.txt 重写 + 自动生成 [codex]

**问题**：`quartz/plugins/emitters/seo.ts` 里 llms.txt 还是硬编码的旧品牌「# Poise Math」，推荐页面是手工清单（10 条），与「聪明的提问者」新定位脱节，新文章永远进不去。
**做法**：

- 品牌与简介改为「聪明的提问者」+ 当前定位文案（与首页 WebSite schema description 一致）
- 从 content index 自动生成全部文章清单：`- [标题](URL)：一行 description`，按 tag/主题分组；MA hub（/math-academy）置顶为核心入口
- 新增 `llms-full.txt`：全部文章的 markdown 全文串联（49 篇规模完全可行），供 AI 引擎一次抓全

### P0-3. KaTeX 资产自托管 [codex]

**问题**：katex.min.css 和 copy-tex.min.js 走 cdn.jsdelivr.net——jsdelivr 在大陆长期不稳定，而目标读者恰是中国家长；CDN 挂掉时数学公式样式全崩。head 里还有一条无用的 cdnjs.cloudflare.com preconnect（没有任何资源从它加载）。
**做法**：

- KaTeX css/fonts/js 随构建打包进站点（node_modules 里已有 katex，emit 到 /static/katex/）
- 移除 cdnjs preconnect

### P0-4. 首页 title 承接搜索词 [codex]

**问题**：首页 `<title>` 只有「聪明的提问者」——新品牌无搜索量，浪费了权重最高的一页。
**做法**（文案已定稿）：改为「聪明的提问者｜Math Academy 中文指南与 AI 时代数学学习」，让首页承接「Math Academy 中文」「Math Academy 怎么样」类核心 query。og:title 同步。仅首页生效，文章页保持现有「标题｜聪明的提问者」格式。

### P0-5. 移除右栏 Graph（关系图谱）组件 [codex]（已确认）

**问题**：postscript.js 721KB，大头是 Graph 组件的 d3 依赖，移动端流量重。
**做法**：`quartz.layout.ts` 中移除 `Component.DesktopOnly(Component.Graph())`；backlinks 组件保留（已能表达文章关联）。验证 postscript.js 体积显著下降（预期 ~300KB 以下）。

## P1 — GEO 强化

### P1-1. 每篇文章提供 Markdown 原文 [codex]

新 emitter：每篇文章额外输出 `/slug.md`（干净 markdown，含 frontmatter 的 title/date/description）；HTML head 加 `<link rel="alternate" type="text/markdown" href="…">`；llms.txt 中说明该约定。AI 爬虫抓取成本大幅降低，引用更准确。

### P1-2. FAQPage 结构化数据 [codex]

/math-academy 已有「常见问题速答」区块。frontmatter 增加 `faq: [{q, a}]` 字段，Head 组件据此输出 FAQPage JSON-LD（仅在有该字段的页面）。MA hub 先上，后续适用文章逐步加。

### P1-3. BreadcrumbList JSON-LD [codex]

Breadcrumbs 组件目前只有视觉，无 schema。补 BreadcrumbList 结构化数据（与视觉面包屑同源生成）。

### P1-4. RSS 全文化 [codex]

`quartz.config.ts` 的 ContentIndex 改为 `rssLimit: 50（或全量）, rssFullHtml: true`；channel description「最近的10条笔记 on …」改为品牌文案。全文 RSS 对聚合器和 AI 引擎都更友好。

### P1-5. 作者实体（E-E-A-T）强化 [codex，链接需 Eric 提供]

BlogPosting 的 author 与 about 页增加 Person schema `sameAs`：公众号「聪明的提问者」介绍页、GitHub、X/微博等。跨平台实体对齐帮助 AI 引擎把「Eric Dong = 聪明的提问者 = MA 中文社区」连成一个实体。

## P2 — 锦上添花

- **P2-1 分析闭环** [Eric+codex]：config `analytics: null` → 接 Cloudflare Web Analytics（免费、无 cookie），否则 SEO 改动无法度量
- **P2-2 lang 一致性** [codex]：`<html lang="zh">` → `zh-CN`，与 og:locale / inLanguage 对齐
- **P2-3 postscript.js 721KB** [需 Eric 决策]：主要是 Graph（d3）+ Search（flexsearch）。非渲染阻塞但移动端流量重。选项 A：去掉右栏关系图谱组件（省 ~400KB）；选项 B：保留现状。属设计取舍
- **P2-4 系列/标签页薄内容** [codex]：human-machine-double-helix 文件夹页与 tag 页补 description（folder 加 index.md），避免薄内容页拉低质量评估

## 验收标准

1. `curl https://tiwenzhe.com/llms.txt` 显示新品牌 + 全部文章自动清单；llms-full.txt 可访问
2. 任一文章页无外部 CDN 依赖（除 giscus 等既有功能），KaTeX 页面断网 CDN 也正常渲染
3. /math-academy 通过 Google Rich Results Test 的 FAQPage 校验；文章页通过 BlogPosting + BreadcrumbList 校验
4. /index.xml 含全文；/slug.md 对任意文章可访问且 head 有 alternate 声明
5. GSC + Bing 均已验证并提交 sitemap；IndexNow ping 在部署日志可见
6. 构建 `npx quartz build` 无新增告警，现有页面视觉零回归

## 实施记录

> 实施日期：2026-08-04；分支：`seo-geo-20260804`。
>
> 本地构建说明：当前机器的 Homebrew `npx` 在解析本仓 package bin 时会在 Quartz CLI 启动前异常占满内存；直接调用同一入口 `node quartz/bootstrap-cli.mjs build --concurrency=1` 构建成功，66 个 Markdown 输入共生成 533 个文件，Quartz 无报错。Cloudflare Pages / GitHub Actions 固定使用 Node 22，工作流仍使用标准 `npx quartz build`。

### P0-1 IndexNow

- 实现：新增根目录 key emitter；新增从构建后 `sitemap.xml` 批量提交 URL 的脚本；新增在 `main` push、`content-updated` repository dispatch 或手动触发时运行的 GitHub Actions workflow，等待 Cloudflare Pages 后提交 IndexNow。
- 文件：`indexnow-key.txt`、`quartz/plugins/emitters/indexNow.ts`、`quartz/plugins/emitters/index.ts`、`quartz.config.ts`、`scripts/ping-indexnow.mjs`、`.github/workflows/indexnow.yaml`。
- 验收：`public/9bae149de565852627c409e66fc93bfd.txt` 已生成且内容与源 key 一致；ping 脚本通过 Node 语法检查和 dry-run payload 检查，读取到 66 个 sitemap URL。真实 API 响应与部署日志需在 push 并完成 Cloudflare 部署后确认；GSC/Bing 验证与 sitemap 提交仍属于 Eric 操作项。

### P0-2 llms.txt 与 llms-full.txt

- 实现：品牌改为“聪明的提问者”；站点简介自动读取首页 description；Math Academy hub 固定置顶；其余已发布文章从 Quartz content index 自动读取并按首个 tag 分组；新增全部文章 Markdown 串联的 `llms-full.txt`，没有硬编码文章清单。
- 文件：`quartz/plugins/emitters/seo.ts`。
- 验收：`public/llms.txt` 包含新品牌、核心入口与 64 篇文章且 URL 无重复；`public/llms-full.txt` 包含 64 个自动生成的 Source 区块。

### P0-3 KaTeX 自托管

- 实现：新增 emitter，从现有 `node_modules/katex/dist` 复制 `katex.min.css`、`copy-tex.min.js` 和 fonts 到 `/static/katex/`；Latex transformer 改用站内 URL；移除无用的 cdnjs preconnect。
- 文件：`quartz/plugins/emitters/katexAssets.ts`、`quartz/plugins/emitters/index.ts`、`quartz/plugins/transformers/latex.ts`、`quartz/components/Head.tsx`、`quartz.config.ts`。
- 验收：构建产物包含 CSS、copy-tex JS 和 60 个 KaTeX font 文件；页面不再引用 jsDelivr KaTeX 资源。Mermaid 等现有功能的既有外链未改动。

### P0-4 首页 title

- 实现：首页 `<title>`、`og:title` 与 `twitter:title` 使用定稿“聪明的提问者｜Math Academy 中文指南与 AI 时代数学学习”；文章页标题格式保持“文章标题｜聪明的提问者”。
- 文件：`quartz/components/Head.tsx`。
- 验收：首页和 Math Academy 文章构建产物已分别核对，标题格式符合要求。

### P0-5 移除 Graph

- 实现：仅从右栏移除 Desktop Graph；Table of Contents 与 Backlinks 保留。
- 文件：`quartz.layout.ts`。
- 验收：`public/postscript.js` 为 109,200 bytes，低于方案预期的 300KB；bundle 中无 Graph 标记。

### P1-1 Markdown 原文

- 实现：新增 Markdown emitter，为每篇文章输出 `/slug.md`，只保留 title/date/description frontmatter 与正文；文章页 head 自动输出 `rel="alternate" type="text/markdown"`；llms.txt 说明该抓取约定。
- 文件：`quartz/plugins/emitters/markdownPages.ts`、`quartz/plugins/emitters/index.ts`、`quartz.config.ts`、`quartz/components/Head.tsx`、`quartz/plugins/emitters/seo.ts`。
- 验收：生成 64 个文章 Markdown 文件；`/math-academy.md` frontmatter 与正文正确，HTML head alternate 指向 `https://tiwenzhe.com/math-academy.md`。

### P1-2 FAQPage

- 实现：扩展 frontmatter 类型支持 `faq: [{q, a}]`；新增可按 slug 合并页面 metadata 的 transformer，并为 Math Academy hub 注入 4 条 FAQ（本站 `content/` 由外部内容仓构建时覆盖，因此 metadata 放在可随站点代码部署的配置中）；Head 仅在 faq 存在且有效时输出 FAQPage JSON-LD。
- 文件：`quartz/plugins/transformers/frontmatter.ts`、`quartz/plugins/transformers/pageMetadata.ts`、`quartz/plugins/transformers/index.ts`、`quartz.config.ts`、`quartz/components/Head.tsx`。
- 验收：`public/math-academy.html` 同时包含可解析的 BlogPosting 与 FAQPage，FAQPage 有 4 个 Question/Answer。Google Rich Results Test 需部署后用线上 URL 复核。

### P1-3 BreadcrumbList

- 实现：Breadcrumbs 组件从与视觉面包屑相同的 ancestry/crumbs 数据生成 BreadcrumbList JSON-LD，不增加可见 DOM 内容。
- 文件：`quartz/components/Breadcrumbs.tsx`。
- 验收：Math Academy 与 about 构建页均包含可解析的 BreadcrumbList，Math Academy 路径含 2 级 ListItem。

### P1-4 RSS 全文化

- 实现：RSS 上限设为 1000（当前等同全量）；开启 `rssFullHtml`；修正 CDATA 内全文 HTML 输出；channel description 改为品牌文案。
- 文件：`quartz.config.ts`、`quartz/plugins/emitters/contentIndex.tsx`。
- 验收：`public/index.xml` 包含 66 个 item、完整 HTML 正文和品牌 channel description。

### P1-5 作者实体

- 实现：统一 Person `@id`；首页 creator、BlogPosting author 增加 GitHub `sameAs`；about 页额外输出 Person schema；代码中保留 TODO，等待 Eric 补公众号、X、微博等公开资料链接。
- 文件：`quartz/components/Head.tsx`。
- 验收：Math Academy 的 BlogPosting author 与 about 页 Person 均只包含 `https://github.com/EricDong` 的 `sameAs`，JSON-LD 可解析。

### 验收结论

- 已通过：自动 llms/llms-full、KaTeX 自托管、首页 title、Graph 移除、Markdown alternate、FAQPage/BreadcrumbList/Person JSON-LD、全文 RSS、完整 Quartz 构建、TypeScript 检查、69 项现有测试。
- 视觉回归：未修改主题样式或正文渲染结构；唯一可见变化为已确认移除右栏 Graph。KaTeX 使用包内原始发行资源，公式样式路径变化但资源内容未二次加工。
- 待部署后确认：IndexNow API 日志、线上 URL 的 Google Rich Results Test、GSC/Bing 验证及 sitemap 提交。
