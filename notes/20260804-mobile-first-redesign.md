# tiwenzhe.com 手机优先重构 — 执行方案（已确认，2026-08-04）

> 执行者：codex。只动本站点 repo（tiwenzhe-site），**不动内容 repo**（vault publish/ 一个字不改）。
> 已由 Eric 拍板的三个决策：①一句一行**只在手机生效**；②Graph **手机隐藏、桌面保留**；③排版**手机+桌面一起调**。
> **重要：本轮 codex 只 commit、不 push**（push main 即 Cloudflare Pages 上线，Eric 最终过目后手动 push）。

## 当前进度（2026-08-04，Claude 预览轮已完成的部分）

以下已实现并经 Eric 看过预览确认，**工作区里是未 commit 的改动，在此基础上继续，不要重做**：

- ✅ A1 一句一行：`quartz/plugins/transformers/sentenceSplit.ts` 已建并注册（transformers/index.ts + quartz.config.ts）；含加粗句（句号在 strong 内）也独立成行；CSS 仅手机断点生效。
- ✅ A2 排版：`quartz/styles/custom.scss` 已有全站行高 1.85/段间距、手机 17px、图片 max-width+height:auto（防变形，Eric 特别提过）+圆角。
- ✅ B Graph → DesktopOnly（quartz.layout.ts）。
- ✅ B 手机可折叠目录：`quartz/components/MobileToc.tsx`（默认收起，beforeBody 中 MobileOnly 包裹）。注意 `.mobile-only` 类在手机断点是 display:inline，custom.scss 里已用 display:block 覆盖——改动样式时别弄丢。
- 已验证：手机 390px 视口首页/长文正常；桌面 1462px 无回归（正常段落流、三栏完好）。

## codex 剩余任务

1. 首屏头部压缩（B）：手机上 PageTitle+Search+Darkmode+ReaderMode 占高检查与压缩，Explorer 确认走汉堡抽屉。
2. Backlinks 手机默认折叠（B，做不动降 P2 不阻塞）。
3. 触屏点击目标 ≥44px（C）。
4. KaTeX/表格页面专项验证（验收标准第 2 条），有问题修 sentenceSplit 边界。
5. 图片变形复查：Eric 反馈预览截图中图片疑似变形；DOM 实测 7 页无失真，已加 height:auto 防御。codex 再抽查 3-5 篇带图文章（含 media/wechat/ 下的 jpg/webp）确认。
6. 跑完整验收标准，全部通过后 commit（不 push）。

## 背景诊断

- Quartz 4 默认三栏布局（断点：mobile 800px / desktop 1200px，见 `quartz/styles/variables.scss`）。
- 手机上竖排顺序：站名→搜索→Explorer→正文→Graph→Backlinks；Graph 触屏几乎不可用。
- TOC 被 `DesktopOnly` 包裹（`quartz.layout.ts`），手机长文无目录。
- 正文 line-height 1.6rem 写死（`quartz/styles/base.scss`），中文偏紧；`custom.scss` 目前只有 3 行，是主要落点。

## 阶段 A：排版层（核心）

### A1. 一句一行 transformer 插件（仅手机生效）

新建 `quartz/plugins/transformers/sentenceSplit.ts`，注册进 `quartz.config.ts` transformers（放在 ObsidianFlavoredMarkdown/GFM 之后、Latex 之后皆可，操作 hast 层最稳）：

- 遍历文章 hast，只处理 `<p>` 元素（含 blockquote 内的 `<p>` 也可以，保守起见第一版**只处理正文直接段落**）。
- 按中文句末标点切句：`。？！`（含后跟 `”』）》"` 等收尾引号/括号时一并归入前句）。**不切**半角 `.`（避免 3.14、URL、英文缩写误切）。
- 每句包成 `<span class="sentence">`；行内元素（链接、`<strong>`、行内 KaTeX `.katex` 等）作为原子节点归属当前句，**绝不切开**。
- 跳过：`pre`、`code`、`table`、`li`、图片段落（`<p>` 内只有 `<img>`）、KaTeX 块级公式容器。
- 段落只含一句时不必包裹（无收益）。

CSS（写进 `quartz/styles/custom.scss`）：

```scss
@media all and ($mobile) {
  article > p > .sentence {
    display: block;
    & + .sentence { margin-top: 0.4em; }
  }
}
```

桌面端不写任何 `.sentence` 规则 → 保持正常段落流。

### A2. 中文排版调优（手机+桌面都调）

全部写在 `custom.scss`，不改 `base.scss`（升级 Quartz 不冲突）：

- **全站**：正文 `line-height: 1.85`；段间距 `p { margin: 1.2em 0 }`；`letter-spacing: 0.01em`（可选，先看效果）。
- **手机断点**：正文等效字号 17–18px（`body { font-size: 1.0625rem }` 级别，具体以真机观感为准）；标题字号相应微调防换行难看。
- **桌面**：正文字号略增（如 1.0625rem），标题保持现有层级比例；正文列宽维持 `$pageWidth`(800px) 不动。
- 图片：`article img { max-width: 100%; border-radius: 6px }`。
- 表格：外层加横向滚动（Quartz 已有 `table-container`，确认手机不撑破即可，撑破则补 `overflow-x: auto`）。

## 阶段 B：布局层

改 `quartz.layout.ts`：

- **Graph**：`Component.Graph()` → `Component.DesktopOnly(Component.Graph())`。
- **TOC**：去掉 `DesktopOnly` 包装改为始终渲染，或加一个 `MobileOnly(TableOfContents)` 到 `beforeBody`（标题/meta 之后）。手机上必须是**默认折叠**的（Quartz TOC 自带 collapse 交互，验证手机样式；不达标就在 custom.scss 补样式）。
- **Backlinks**：保留，手机上默认折叠（Quartz Backlinks 无折叠选项时，用 `<details>` 思路或 CSS 收纳；做不动就降级为 P2 留待后续，不阻塞）。
- **首屏精简**：手机上让标题尽快出现——检查现有 mobile 头部（PageTitle + Search + Darkmode + ReaderMode + Explorer）实际占高，把这一组压缩到一~两行内；Explorer 确认走汉堡/抽屉而非展开列表。

## 阶段 C：体验层（小项，允许部分降级为后续）

- 触屏点击目标 ≥44px：TagList 标签、页脚链接、TOC 条目。
- Popover：确认触屏无 hover 时链接直接跳转、无卡死；有问题再处理。
- 阅读进度条：可选，最后做。

## 验收标准（每阶段 gate）

1. `npx quartz build --serve` 本地跑通，Chrome DevTools 390px 模拟逐页检查：
   - 首页 `/`、枢纽长文 `/math-academy`、含图片文章（如 `math-learning-stuck-because-steps-are-too-high`）、含 KaTeX/表格的文章各一篇。
2. 一句一行边界：KaTeX 公式（行内+块级）、列表、代码块、表格、图片段落**均不被切句**；行内链接不被拆断。
3. 桌面端（1440px）回归：无 `.sentence` 换行效果、三栏不破版、Graph 正常。
4. Lighthouse mobile 分数不低于改前基线（改前先跑一次记录）。
5. 每阶段独立 commit；A/B/C 分开 push，每次 push 后线上抽查一次（部署约 1-2 分钟）。

## 明确不做

- 不改内容 repo / vault publish/ 任何 markdown。
- 不改 `$pageWidth`、不换字体家族、不动 Cloudflare 配置。
- 不把一句一行写死进内容（随时可通过删 CSS/插件整体回退）。
