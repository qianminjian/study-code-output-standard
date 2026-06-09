---
name: study-code-output-standard
description: |
  反向阅读任意代码项目，按"study-code-output-standard"方法论生成 12 篇标准资产文档到项目根目录的 asset-docs/。
  触发场景：用户说"反向阅读"、"提炼资产"、"分析项目结构"、"输出项目文档"、"code2docs"、"reformat this project"等。
  适用：任何规模的 全栈 / 后端 / 前端 / 多端 项目（1 万行+）。
  不适用：1-2 周 Demo、纯文档项目、单一库/SDK。
  输出：项目根目录/asset-docs/（12 篇资产 + 12 模板 + 12 Prompt + 5 脚本 + 3 references）。
---

# Skill: study-code-output-standard

> **路径约定**：本文档用以下占位符描述路径，**Claude 须用实际项目根目录替换**：
> - `<项目根>` = 用户调用 skill 时所在的项目根目录（默认 `pwd`）
> - `<指定项目>` = 用户用 `--path <path>` 显式指定的项目目录
> - `<skill 目录>` = 本 skill 安装位置（即仓库根目录，安装后是 `~/.claude/skills/study-code-output-standard/`）
> - **本 skill v2.1 起采用扁平布局**：SKILL.md、scripts/、references/、templates/、ai-prompts/、methodology/ 都直接在 `<skill 目录>` 下
> - **不要把 `<项目根>` 当作 shell 变量执行**（不存在 `${项目根}` 这种 bash 语法）

## 触发条件

当用户输入以下任意一种时，触发本 skill：

- `/study-code-output-standard`
- `/reverse-read` `/code2docs` `/asset-extract`
- "反向阅读这个项目" / "提炼项目资产" / "分析项目结构" / "输出项目文档"
- "reformat this project" / "generate project docs" / "extract assets"

## 目标行为

用户在 `<项目根>`（或 `<指定项目>`）下，调用本 skill 后：

1. **自动按 6 步法执行反向阅读**（勘探→分类→抽取→校验→标注→派送）
2. **输出到 `<项目根>/asset-docs/`**
3. **生成 `<项目根>/CLAUDE.md`**（轻量索引，**按需加载**）
4. **生成 `<项目根>/CLAUDE-ASSET.md`**（资产详情，**按需加载**）

## 6 步法执行流程

### Step 1 · 勘探（Reconnaissance）

**目标**：建立项目"心智地图"

**必做动作**：
- Bash: `tree -L 3 <项目根>` （macOS 用 `find . -maxdepth 3 -not -path '*/node_modules*' -not -path '*/.git*' | head -100`）
- Read: `<项目根>/README.md`
- Read: `<项目根>/package.json` 或 `<项目根>/pom.xml` 或 `<项目根>/go.mod` 或 `<项目根>/requirements.txt`（按技术栈）
- 找 5 个最关键入口文件（main / Application / index.js / app.py）

**输出**：项目骨架笔记（写到对话中）

### Step 2 · 分类（Classification）

**目标**：决定 12 篇资产覆盖范围

**必做动作**：
- Read: `<skill 目录>/references/asset-types.md`
- 套用适用矩阵，决定 12 篇哪些输出 / 哪些占位 / 哪些省略
- 不适用也保留编号（如纯后端项目 07/08/09 写"本项目无前端"）

**输出**：12 篇覆盖决策表

### Step 3 · 抽取（Extraction）— AI 主战场

**目标**：生成 12 篇资产初稿

**必做动作**：

1. Bash: `bash <skill 目录>/scripts/init-asset-docs.sh <项目根>`
   - 效果：创建 `<项目根>/asset-docs/` 骨架

2. 按 04-工作流 §3.1 的依赖顺序，逐个生成：

| 顺序 | 资产 | Prompt 文件 |
|:-:|---|---|
| 1 | 02-数据模型与表结构 | `<项目根>/asset-docs/ai-prompts/02-数据模型与表结构.md` |
| 2 | 03-API 清单 | `<项目根>/asset-docs/ai-prompts/03-后端-Controller接口清单.md` |
| 3 | 04-Mapper 清单 | `<项目根>/asset-docs/ai-prompts/04-后端-Mapper操作清单.md` |
| 4 | 06-安全认证 | `<项目根>/asset-docs/ai-prompts/06-后端-安全认证.md` |
| 5 | 05-服务与业务 | `<项目根>/asset-docs/ai-prompts/05-后端-服务与业务逻辑.md` |
| 6 | 07-前端页面（如适用）| `<项目根>/asset-docs/ai-prompts/07-前端-页面与组件清单.md` |
| 7 | 08-前端状态（如适用）| `<项目根>/asset-docs/ai-prompts/08-前端-状态管理与路由.md` |
| 8 | 09-静态/多端（如适用）| `<项目根>/asset-docs/ai-prompts/09-静态前台.md` |
| 9 | 10-业务流图 | `<项目根>/asset-docs/ai-prompts/10-业务流图.md` |
| 10 | 11-技术债 | `<项目根>/asset-docs/ai-prompts/11-技术债与遗留项.md` |
| 11 | 12-修复建议 | `<项目根>/asset-docs/ai-prompts/12-修复建议与优先级.md` |
| 12 | 01-系统总览 | `<项目根>/asset-docs/ai-prompts/01-系统总览.md` |
| 13 | 00-文档索引 | （无 Prompt，直接生成） |

3. 每篇资产**必须**：
   - 顶部 frontmatter（id / version / last_updated / data_source / code_version / owner / ai_consumable）
   - 顶部引用块 `> 整理时间 · 数据来源`
   - 严格按 templates/ 对应文件结构
   - 强制列填齐
   - 严重度 P0-P3 标注
   - 元信息表收尾

4. 单篇失败不阻断，记录并跳过，最后报告

### Step 4 · 校验（Validation）

**目标**：确保资产与代码事实一致

**必做动作**：
- Bash: `bash <项目根>/asset-docs/scripts/validate-all.sh`
- 修复脚本报告的所有错误
- 抽 5-10 个端点对照 Swagger / Postman 验证（人工）

### Step 5 · 标注（Annotation）

**目标**：把代码的"问题"与"风险"显式标出

**必做动作**：
- Bash: `bash <项目根>/asset-docs/scripts/scan-antipatterns.sh`
- Read: `<skill 目录>/references/anti-patterns.md`
- 把扫出的反模式按标签体系（@sqlinjection / @secret-leak / @cors-wildcard / @perm-mismatch / @n+1 / @xss / @hardcoded 等）标注到 11-技术债清单

### Step 6 · 派送（Delivery）

**目标**：让资产可发现、可消费、可演进

**必做动作**：

1. Bash: `bash <skill 目录>/scripts/write-claude-index.sh <项目根>`
   - 效果：生成 `<项目根>/CLAUDE.md`（**轻量索引，标"按需加载"**）

2. Bash: `bash <skill 目录>/scripts/write-claude-asset.sh <项目根>`
   - 效果：生成 `<项目根>/CLAUDE-ASSET.md`（**详细资产清单**）

3. 提示用户接入 CI（`.github/workflows/docs-validate.yml`）

4. 通知团队"资产 v1.0 已就绪"

## 进度报告

每完成一步，输出一段进度报告：

```
=== Step 1/6 勘探 ===
✓ 找到入口：src/main/java/com/example/Application.java
✓ 技术栈：Java 17 + Spring Boot 3.2
✓ 项目规模：约 12 万行
→ 耗时：8 秒

=== Step 2/6 分类 ===
✓ 适用：全栈 Web 项目
→ 12 篇资产全部输出
→ 耗时：3 秒
...
```

## 错误处理

| 错误 | 处理 |
|---|---|
| `<项目根>` 不是有效目录 | 报告并停止 |
| 方法论文档找不到 | 报告并提示重新 install |
| AI 抽取出错 | 保留已有 + 跳过 + 报告（不阻断） |
| 校验脚本报错 | 列出问题但不阻断，给人工修复入口 |
| 用户中断 | 保存当前进度，下次继续 |
| 已有 asset-docs/ | 询问是否覆盖（CLI：自动跳过） |

## 重要约束

1. **路径处理**：
   - `<项目根>` 来自 `--path` 参数或用户当前工作目录
   - 跨平台：使用 `<项目根>` 而非硬编码 `/`
   - Windows 路径：脚本内部用 `cygpath` 转换（如 Git Bash 环境）

2. **方法论定位**：
   - 优先用 `<skill 目录>`（skill 安装时记录的绝对路径）
   - 退化：从当前工作目录向上找 5 层

3. **资产输出位置**：
   - 严格 `<项目根>/asset-docs/`
   - 不写 `<项目根>/docs/`（避免与已有项目冲突）

4. **CLAUDE.md 双文件策略**：
   - `CLAUDE.md` ≤ 80 行（轻量索引 + "按需加载"标注）
   - `CLAUDE-ASSET.md` 详细（按需 Read）

5. **绝对禁止**：
   - 不写硬编码密钥/密码（用 `<REDACTED>`）
   - 不写自定义严重度（统一 P0-P3）
   - 不省元信息头
   - 不省 frontmatter（7 必填字段 + 1 可选 `severity_taxonomy`，详见 `02-目录与命名规范.md §3`）
   - 不省强制列

## 输出完成报告

执行完 6 步法后输出：

```
═══════════════════════════════════════
  反向阅读完成
═══════════════════════════════════════
✓ 目标项目：<项目根>
✓ 资产输出：<项目根>/asset-docs/
✓ 索引文件：<项目根>/CLAUDE.md
✓ 详情文件：<项目根>/CLAUDE-ASSET.md
✓ 12 篇资产：全部生成
✓ 校验：bash <项目根>/asset-docs/scripts/validate-all.sh
✓ 总耗时：X 分 Y 秒

下一步：
  1. 人工 review 关键资产
  2. 接入 CI（见 references/methodology.md §9）
  3. 让 AI 写新功能：喂 01+02+03（最小集）
═══════════════════════════════════════
```

## 元信息

| 字段 | 值 |
|---|---|
| 配套 | references/{methodology,asset-types,anti-patterns}.md |
| 安装 | install.sh (Mac/Linux) / install.ps1 (Windows) |
| 适用 | Claude Code 0.2+ / Cursor 0.30+ / Copilot Workspace |
