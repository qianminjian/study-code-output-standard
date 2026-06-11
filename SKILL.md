---
name: study-code-output-standard
version: 3.0.0
description: |
  反向阅读任意代码项目，按"study-code-output-standard"方法论生成 12 篇标准资产文档到项目根目录的 asset-docs/。
  触发场景：用户说"反向阅读"、"提炼资产"、"分析项目结构"、"输出项目文档"、"code2docs"、"reformat this project"、"深度思考后提炼资产"等；亦可由深度思考 slash-command 触发：`/ttt`、`/ts`、`/tp`、`/tt`、`/tttt` 加上"提炼资产"作为动作目标。
  适用：任何规模的 全栈 / 后端 / 前端 / 多端 项目（1 万行+）。
  不适用：1-2 周 Demo、纯文档项目、单一库/SDK。
  输出：项目根目录/asset-docs/（12 篇资产 + 1 CHANGELOG + 1 README + 1 CLAUDE.md.tmpl，模板/prompt/脚本留在 skill 目录）。
---

# Skill: study-code-output-standard

> **路径约定**（：
> - `${PROJECT_ROOT}` = 用户调用 skill 时所在的项目根目录（默认 `pwd`）
> - `${SPECIFIED_PROJECT}` = 用户用 `--path <path>` 显式指定的项目目录
> - `${SKILL_HOME}` = 本 skill 安装位置（即仓库根目录，安装后是 `~/.claude/skills/study-code-output-standard/`）
> - **本 skill 采用仓库根 = skill 根布局**：SKILL.md、scripts/、assets/、references/ 都在 `${SKILL_HOME}` 下
>
> **真实路径示例**（macOS 软链安装后）：
> ```
> ${SKILL_HOME}    = /Users/me/.claude/skills/study-code-output-standard
> ${PROJECT_ROOT}  = /Users/me/work/my-project
> ${TARGET}        = ${PROJECT_ROOT}/asset-docs
> ```
>
> **⚠️ 占位符仅供人/AI 阅读，不是 bash 变量**。脚本里要取实际值时，请用 init-asset-docs.sh 内的 `SCRIPT_DIR`/`TARGET` 推断逻辑。

## 触发条件

当用户输入以下任意一种时，触发本 skill：

- `/study-code-output-standard`
- `/reverse-read` `/code2docs` `/asset-extract`
- `/ttt` `/ts` `/tp` `/tt` `/tttt` 后跟"提炼资产" / "反向阅读" / "分析项目"（深度思考类命令亦可触发本 skill 实际执行）
- "反向阅读这个项目" / "提炼项目资产" / "分析项目结构" / "输出项目文档"
- "reformat this project" / "generate project docs" / "extract assets"

> **为什么把 `/ttt` 等加进触发词**：用户的实际入口往往是 `/ttt <动作>` 或 `/ts <动作>`，而不是直接 `/study-code-output-standard`。把深度思考类 slash-command 列为入口，能让本 skill 真正被触发。

## references/prompts/ 实际使用

> **明确定位**，避免与 assets/ @prompt 引用块重复：

| 资源 | 谁读 | 用途 |
|---|---|---|
| **`${SKILL_HOME}/assets/<NN>-*.md.tmpl`** | **AI 实际读取** | 含 `@prompt:` 引用块 + frontmatter + 占位结构 → AI 严格按模板写资产 |
| **`${SKILL_HOME}/references/prompts/<NN>-*.md`** | **人类维护者 review** | AI 写资产时的"灵感库 / 完整 prompt 参考"，人类维护时 audit 写出质量 |
| **`${SKILL_HOME}/references/methodology/04-反向阅读工作流.md`** | 人类 + AI 共同 | 6→7 步法详细方法论 |
| **`${SKILL_HOME}/references/methodology/07-典型案例与反模式.md`** | 人类 + AI 共同 | 24 个反模式标签扫法 + 老朋友 5 案例 |

> **⚠️ 重要工作流**：
> - ❌ **不要**让 AI 直接读 `references/prompts/` 目录生成资产——实测发现实际**没用上**（设计意图 vs 实际使用脱节）
> - ✅ **应该**让 AI 读 `assets/<NN>-*.md.tmpl`（含 @prompt 引用块 + 完整骨架）
> - ✅ `references/prompts/` 保留作为人类维护者的"prompt 灵感库"——review AI 写出时对照
> - 单点真源原则：模板维护时**同步刷** `references/prompts/<NN>-*.md`（注释提示）

## 老系统快速通道（

> 适用：jQuery 1.x / 无 DDL / 无 Swagger / 无 git / 无 README / 上古前后端分离站（如 wxcbrc）

5 步走完：

1. **Step 1 勘探必做**：`git init` + 首次 commit（无 git 时主动初始化）
2. **02 必启用 §2-B 推断模式**——所有表加 ⚠️，元信息标"DDL 来源：无（推断）"
3. **03 摘要表 "Swagger 启用"列填"否"** + 取消 Swagger 校对（Step 4 用 grep 双向对账）
4. **06 必加 11 项 OWASP 清单**——高亮 4 个 P0（@sqlinjection / @cors-wildcard / @actuator-exposure / @wrong-token-hdr）
5. **09 静态 + jQuery 检测**：global.js baseUrl 硬编码 / `$.html()` XSS 风险

> 详细降级矩阵见 `references/methodology/01-资产清单与适用场景.md` "老旧系统"分支

## 写路径验证（

> ⚠️ **每篇资产写完立即 grep 验证**（确保写对位置）——本次完整跑 13 篇时发现 cat heredoc 写 .md 路径错会 silent 写错位置

**必跑命令**（每篇写完 5 秒内）：

```bash
# 验证文件存在 + @meta 块正确
head -3 asset-docs/02-数据模型与表结构.md | grep -E "@meta|id"
# 期望输出: <!-- @meta { "id": "02-数据模型与表结构", ... -->

# 验证文件数（应 13 份资产 + CHANGELOG + README + CLAUDE.md.tmpl = 16 文件）
ls asset-docs/ | wc -l   # 期望: 16

# 验证 frontmatter id 与文件名一致
for f in asset-docs/[0-9][0-9]-*.md; do
  basename "$f" .md
  grep "\"id\":" "$f" | head -1
done
# 期望: 每行 basename 与 id 的中文名一致
```

**典型症状（说明写错位置）**：
- `asset-docs/` 下文件数 < 13 → 写漏了
- frontmatter `id` 与文件名不一致 → 写错模板
- @meta 块缺失 → Write 工具被截断（**大文件风险**）
- 文件出现在 `~/.claude/skills/study-code-output-standard/` 而非用户项目 → 用了 `${SKILL_HOME}` 相对路径

**Skill 自身保护**（v2.4）：
- init 脚本写 `.asset-docs.lock` 文件锁——重复 init 会被拦截
- 删除 lock 或加 `--force` 强制覆盖

## Token 预算（

完整跑 13 篇资产的**预估 token 量级**（基于 wxcbrc 1.5 万行实测）：

| 资产 | 字数（小项目）| 字数（中项目）| 字数（大项目）|
|---|:-:|:-:|:-:|
| 01 系统总览 | 3000-5000 | 5000-8000 | 8000-15000 |
| 02 数据模型 | 4000-6000 | 6000-10000 | 10000-20000 |
| 03 Controller | 3000-5000 | 5000-8000 | 8000-15000 |
| 04 Mapper | 3000-5000 | 5000-8000 | 8000-15000 |
| 05 服务 | 4000-6000 | 6000-10000 | 10000-20000 |
| 06 安全 | 4000-6000 | 6000-10000 | 10000-20000 |
| 07 前端 | 3000-5000 | 5000-8000 | 8000-15000 |
| 08 状态 | 3000-5000 | 5000-8000 | 8000-15000 |
| 09 静态 | 2000-3000 | 3000-5000 | 5000-8000 |
| 10 业务流 | 4000-6000 | 6000-10000 | 10000-20000 |
| 11 技术债 | 3000-5000 | 5000-8000 | 8000-15000 |
| 12 修复 | 2000-3000 | 3000-5000 | 5000-8000 |
| 13 反模式 | 3000-5000 | 5000-8000 | 8000-15000 |
| **合计** | **40000-64000** | **64000-104000** | **104000-186000** |

> **⚠️ 实战建议**：
> - 小项目（< 1 万行）：一次写完 OK，~50000 字
> - 中项目（1-10 万行）：**强烈建议分 4 阶段**，每阶段人类 review（详见 references/methodology/04 §分批工作流）
> - 大项目（> 10 万行）：**必须分批**，单次 LLM 上下文会爆
> - **每篇写完立即 `head -3 asset-docs/02-数据模型与表结构.md` 验证 @meta + 文件名一致**（避免路径错 silent 失败）

## 目标行为

用户在 `${PROJECT_ROOT}`（或 `${SPECIFIED_PROJECT}`）下，调用本 skill 后：

1. **自动按 7 步法执行反向阅读（**（勘探→分类→抽取→校验→标注→派送）
2. **输出到 `${PROJECT_ROOT}/asset-docs/`**
3. **生成 `${PROJECT_ROOT}/CLAUDE.md`**（轻量索引，**按需加载**）
4. **生成 `${PROJECT_ROOT}/CLAUDE-ASSET.md`**（资产详情，**按需加载**）

## 串行生成模式 (v3.0)

> **适用**：所有项目规模。小/中型项目默认走此模式。大型项目（>10 万行）推荐用 `## 并行生成模式 (v3.5)` 提速 + 缓解上下文溢出。
> **机制**：编排者（当前 agent）按依赖顺序**逐个**生成 12 篇资产，单一上下文、串行思考，适合 < 10 万行项目。
> **何时降级到 v3.0**：见 `## 并行生成模式 (v3.5)` 的"降级检查点"。

### Step 0 · 启动确认（

**目标**：避免"启动即跑全量 6 步法"的不可控体验，先与用户确认范围/覆盖/owner。

**必做动作**（Claude Code 必弹 AskUserQuestion）：

1. **范围**（范围选项）：
   - `全量 12 篇`（默认）
   - `仅 11+12 技术债与修复`（快速摸底）
   - `自定义范围`（用户指定编号）

2. **覆盖策略**（已有 `asset-docs/` 时）：
   - `覆盖`（删旧重做）
   - `合并`（保留已有 + 仅补空）
   - `跳过`（保留全部）

3. **owner / code_version**：
   - owner = `<团队名>`（必填）
   - code_version = `git:<hash>` | `<unversioned>` | 留空

**退出条件**：用户已答完三问（即便选"默认"也要显式确认）。

### Step 1 · 勘探（Reconnaissance）

**目标**：建立项目"心智地图"

**必做动作**：
- Bash: `tree -L 3 ${PROJECT_ROOT}` （macOS 用 `find . -maxdepth 3 -not -path '*/node_modules*' -not -path '*/.git*' | head -100`）
- Read: `${PROJECT_ROOT}/README.md`
- Read: `${PROJECT_ROOT}/package.json` 或 `${PROJECT_ROOT}/pom.xml` 或 `${PROJECT_ROOT}/go.mod` 或 `${PROJECT_ROOT}/requirements.txt`（按技术栈）
- 找 5 个最关键入口文件（main / Application / index.js / app.py）

**输出**：项目骨架笔记（写到对话中）

### Step 2 · 分类（Classification）

**目标**：决定 12 篇资产覆盖范围

**必做动作**：
- Read: `${SKILL_HOME}/references/methodology/01-资产清单与适用场景.md`
- 套用适用矩阵，决定 12 篇哪些输出 / 哪些占位 / 哪些省略
- 不适用也保留编号（如纯后端项目 07/08/09 写"本项目无前端"）

**输出**：12 篇覆盖决策表

### Step 3 · 抽取（Extraction）— AI 主战场

**目标**：生成 12 篇资产初稿

**必做动作**：

1. Bash: `bash ${SKILL_HOME}/scripts/init-asset-docs.sh ${PROJECT_ROOT}`
   - 效果：创建 `${PROJECT_ROOT}/asset-docs/` 骨架

2. 按 04-工作流 §3.1 的依赖顺序，逐个生成：

| 顺序 | 资产 | 模板文件 |
|:-:|---|---|
| 1 | 02-数据模型与表结构 | `${SKILL_HOME}/assets/02-数据模型与表结构.md.tmpl` |
| 2 | 03-API 清单 | `${SKILL_HOME}/assets/03-后端-Controller接口清单.md.tmpl` |
| 3 | 04-Mapper 清单 | `${SKILL_HOME}/assets/04-后端-Mapper操作清单.md.tmpl` |
| 4 | 06-安全认证 | `${SKILL_HOME}/assets/06-后端-安全认证.md.tmpl` |
| 5 | 05-服务与业务 | `${SKILL_HOME}/assets/05-后端-服务与业务逻辑.md.tmpl` |
| 6 | 07-前端页面（如适用）| `${SKILL_HOME}/assets/07-前端-页面与组件清单.md.tmpl` |
| 7 | 08-前端状态（如适用）| `${SKILL_HOME}/assets/08-前端-状态管理与路由.md.tmpl` |
| 8 | 09-静态/多端（如适用）| `${SKILL_HOME}/assets/09-静态前台.md.tmpl` |
| 9 | 10-业务流图 | `${SKILL_HOME}/assets/10-业务流图.md.tmpl` |
| 10 | 11-技术债 | `${SKILL_HOME}/assets/11-技术债与遗留项.md.tmpl` |
| 11 | 12-修复建议 | `${SKILL_HOME}/assets/12-修复建议与优先级.md.tmpl` |
| 12 | 01-系统总览 | `${SKILL_HOME}/assets/01-系统总览.md.tmpl` |
| 13 | 00-文档索引 | （无模板，直接生成） |

3. 每篇资产**必须**：
   - 顶部 frontmatter（id / version / last_updated / data_source / code_version / owner / ai_consumable）
   - 顶部引用块 `> 整理时间 · 数据来源`
   - 严格按 assets/ 对应文件结构
   - 强制列填齐
   - 严重度 P0-P3 标注
   - 元信息表收尾

4. 单篇失败不阻断，记录并跳过，最后报告

### Step 4 · 校验（Validation）

**目标**：确保资产与代码事实一致

**必做动作**：
- Bash: `DOCS_DIR=${PROJECT_ROOT}/asset-docs bash ${SKILL_HOME}/scripts/check-all.sh`
  -  scripts 留在 `${SKILL_HOME}`（不再复制到用户项目，避免污染）
  - 向后兼容：老 `validate-all.sh` shim 仍可调，自动转 `check-all.sh`
  - `check-all.sh` 不再静默报"全部校验通过"——子脚本 `exit 1` 会显式标 `==> 校验完成：N 个步骤失败`
- 修复脚本报告的所有错误

> ⚠️ **必须人工抽样 5-10 个端点 + 3-5 个业务流**，否则视为半成品——脚本只发现候选名单，最终正确性靠人。

- 抽 5-10 个端点对照 Swagger / Postman 验证（人工）

**⚠️ 无 Swagger / Postman 时的替代校验**（：

很多老项目（无 OpenAPI 文档、无 Postman 集合）不能直接对照。以下是 3 种降级方案，按可信度从高到低：

1. **grep 端点 ↔ grep 前端 HTTP 模块双向对账**
   - 后端端点：`grep -rE "@(Get|Post|Put|Delete)Mapping" ${SRC_DIR} | wc -l`
   - 前端调用：`grep -rE "http\.(get|post|put|delete)\(" ${WEB_SRC}/src/http/ | wc -l`
   - 若后端端点 = 文档化数 = 前端调用数（±2 容差），视为对齐

2. **跑 `mvn spring-boot:run` 看启动日志 `Mapped` 行**
   - Spring Boot 启动会打印所有 `@RequestMapping` 路径
   - `grep "Mapped \"\\(\\w*\\) \\(GET\\|POST\\|PUT\\|DELETE\\)" spring-boot-run.log > /tmp/mapped.txt`
   - 与 `03-Controller` 表格对比

3. **对照 `WebSecurityConfig.permitAll` 与 Controller `@PreAuthorize` 交集**
   - 公开端点 = `permitAll` 路径 ∩ 实际 Controller `@GetMapping` 路径
   - 交集 > 5 → 检查是否过度公开（典型 P0 `@actuator-exposure`）

### Step 5 · 反模式深度标注（Annotation · v2.2 改名 + 派生 13 号资产）

**目标**：把代码的"问题"与"风险"显式标出，**派生独立的 13-反模式扫描报告**（不再只写到 11-技术债清单）。

**必做动作**：

1. Bash: `SRC_DIR=${SRC_DIR} XML_DIR=${XML_DIR} bash ${SKILL_HOME}/scripts/scan-antipatterns.sh`
2. Read: `${SKILL_HOME}/references/methodology/07-典型案例与反模式.md`
3. 把扫出的反模式**分别落到两份资产**：
   - **`11-技术债与遗留项.md`**：只收"**影响业务且有修复方案**"的反模式（如 @sqlinjection / @secret-leak / @cors-wildcard）
   - **`13-反模式扫描报告.md`（**：收"**模式分布 / 扫法 / 降级建议**"，按 24 个标签分类，含统计与风险雷达
4. 严重度 P0-P3 标注，位置 `<文件>:<行号>` 格式

**为什么拆 13 号**：原 11-技术债清单被 24 个反模式标签淹没（典型 30+ 条），不易聚焦业务问题；13 号报告专注"反模式本身"——标签分布 / 严重度热图 / 降级建议。

### Step 6 · 派送（Delivery）

**目标**：让资产可发现、可消费、可演进

**必做动作**：

1. Bash: `bash ${SKILL_HOME}/scripts/write-claude-index.sh ${PROJECT_ROOT}`
   - 效果：生成 `${PROJECT_ROOT}/CLAUDE.md`（**轻量索引，标"按需加载"**）

2. Bash: `bash ${SKILL_HOME}/scripts/write-claude-asset.sh ${PROJECT_ROOT}`
   - 效果：生成 `${PROJECT_ROOT}/CLAUDE-ASSET.md`（**详细资产清单**）

3. 提示用户接入 CI（`.github/workflows/docs-validate.yml`）

4. 通知团队"资产 v1.0 已就绪"

### Step 7 · 资产回写（Writeback · v2.2 新增 · 闭环）

**目标**：让"**改代码 = 改资产；改资产 = 改代码**"金句真正落地——资产不是一次性附件。

**为什么新增本步**：原 6 步法只到 Step 6 派送，缺少"代码改完回头刷资产"机制，导致资产很快与代码漂移。Step 7 强制把回写变成 SLA。

**必做动作**：

1. **改代码 → 同步刷资产**：
   - 改 Controller → 同步 `03-Controller接口清单`
   - 改 Mapper → 同步 `02-数据模型` + `04-Mapper操作清单`
   - 修 P0 → 同步 `11-技术债`（标"已修复"）+ `12-修复建议`（标"已完成"）
   - 改 Service 业务流 → 同步 `05-服务与业务` + `10-业务流图`

2. **CI 接入**：
   ```yaml
   # .github/workflows/docs-validate.yml
   on:
     pull_request:
       paths: ['src/**', 'asset-docs/**']
   jobs:
     validate:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - run: bash $SKILL_HOME/scripts/check-all.sh
   ```

3. **last_updated 时效校验**：
   - `check-meta.sh` 每日检查 12 篇 `last_updated` 距今 > 30 天 → 告警（
   - 不阻断 PR，但要求 owner 在合并前刷新

4. **版本对齐**：
   - 代码 bump 大版本（v2 → v3）→ 资产同步 bump（同步改 12 篇 `version` + CHANGELOG）
   - 季度：资产 review，重排严重度

**退出条件**：
- CI 接入完成（PR 必跑 `check-all.sh`）
- `last_updated` 30 天告警机制就位
- 团队 owner 接受"改代码 = 改资产"SLA

## 并行生成模式 (v3.5)

> **适用**：大型项目（> 10 万行）或上下文溢出场景。
> **机制**：编排者（当前 agent）按 **4 阶段管线** 用 `Agent` 工具 `run_in_background: true` 并行 spawn 多个 worker，每 worker 独立读代码 → 按模板写一篇资产 → 返回摘要。
> **何时回退到 v3.0**：项目 < 1 万行 / Haiku 模型 / Worker 失败 ≥ 3/7 / 编排者 context < 20K（见 §7.2）。

### A. 触发条件

满足以下**任一**条件，编排者从 v3.0 切换到 v3.5：

1. 项目规模 > 10 万行（`cloc` 估算）
2. 单 agent 上下文已用 > 150K tokens
3. 用户显式指定 `--mode=parallel` 或 `--mode=v3.5`

否则走 v3.0 串行。**0 新文件**：所有 worker prompt 逻辑内联在本节。

### B. 动态自适应并发（模型检测）

**模型能力检测**（编排者 Step 0 必做）：

| 信号 | 来源 |
|------|------|
| `CLAUDE_CODE_MODEL` env | `opus` / `sonnet` / `haiku` |
| 系统提示中的模型标识 | 匹配 `claude-opus` / `claude-sonnet` / `claude-haiku` |
| 上下文剩余 token | > 150K = 高 / 100-150K = 中 / < 100K = 低 |

**并发决策表**：

| 模型 | Phase 1 并发数 | 分配策略 |
|------|:-:|---|
| **Opus** | 5-7 并行 | 每个资产独立 worker，全部 `run_in_background: true` |
| **Sonnet** | 3-4 并行 | 合并共享文件读取：W1=02+04（共享 XML）/ W2=03+06（共享 Controller）/ W3=07+08+09（前端全部）|
| **Haiku** | 0 并行 | **降级 v3.0**（context 太紧，多 agent 开销 > 收益）|

**自动降级触发**：Step 1+2 消耗 > 50K tokens / Agent spawn 失败 2 次 / 项目 < 1 万行 → 降一档（Opus 7→4, Sonnet 4→2），最终回 v3.0。

### C. 4 阶段管线

```
Phase 1 ─── 7 worker 并行（02/03/04/06/07/08/09，无依赖，全部读源码）
           全栈 7 个 / 纯后端 4 个（跳 07/08/09）/ 纯前端 3 个（跳 02-06）
           run_in_background: true 全部同时启动 → 编排者等待全部完成
    ▼
Phase 2 ─── 1 worker（05 服务逻辑，可选依赖 03+04 输出）
    ▼
Phase 3 ─── 1 worker（10 业务流图，依赖 Phase 1+2 全部）
    ▼
Phase 4 ─── 并行 11+13，然后 12
           11 技术债 + 13 反模式（并行）→ 12 修复建议（派生自 11）
    ▼
编排者 ─── 01 系统总览 → 00 文档索引（自己写，不 spawn）
```

**Phase 1 并行可行性**：02-09 资产**输出无依赖**（各自写到不同文件），但**文件读取有重叠**（02/04 共享 XML；06 与 02/03/04 跨目录扫描；07/08 边界模糊）。重叠不冲突——同一文件被读出不同维度。交叉引用一致性推迟到 Step 4 校验阶段统一处理（v3.0 串行时一致性天然存在，但 v3.0 也需要 human review 抽查，所以校验量不增加）。

### D. 4 种 Worker 认知变体（内联指令）

> 编排者 spawn worker 时按资产编号选择变体，对应指令直接拼进 prompt。

| 变体 | 适用资产 | 核心任务 | 关键 guard |
|------|---------|---------|-----------|
| **A: Extract** | 02, 03, 04, 07, 08, 09 | grep→提取→填表→计数校验 | grep 数 = 表格行数 |
| **B: Analyze** | 06, 11, 13 | 模式匹配→严重度分类→根因分析 | 每条结论带 `<file>:<line>` |
| **C: Synthesize** | 05, 10 | 调用链追踪→语义重建→决策点 | 如实报告异常路径数，不足时 `@incomplete-coverage` |
| **D: Aggregate** | 01, 00, 12 | 读上游资产→交叉校验→综合 | 不复制粘贴，必须合成 |

**共享 Preamble**（5 铁律，违规 = 输出作废）：

```
1. 完全反应：代码中每个实体/端点/类都必须出现在输出中
2. 不丢失：grep 计数 = 表格行数，差 1 就重新扫
3. 不幻觉：每条结论带 <file>:<line> 证据，找不到写"未确认"
4. 不偷懒：深度分析是强制的，不抽样，不全读等于没读
5. 不怕消耗 token：宁可读 50 个文件产出完整资产
```

**诚实标注**：铁律 1-3 可脚本/审计验证（硬铁律）；铁律 4-5 仅靠 worker 自觉 + 审计间接推断（软约束）。v3.0 串行同样面临 4-5 不可硬验证。

**变体 A 扫描流程**（Extract）：
1. 跑 grep/find 记录精确计数 → 2. 逐个 Read 全文不跳过 → 3. 按模板结构填表 → 4. 重 grep 计数校验

**变体 B 扫描流程**（Analyze）：
1. 跑 `scan-antipatterns.sh` → 2. 对命中 Read 源文件确认非误报 → 3. 手动 grep 补 TODO/FIXME/password/secret → 4. 06 必逐项对照 OWASP Top 10 → 5. 分类严重度 + 根因类型

**变体 C 扫描流程**（Synthesize）：见 references/methodology/04 §3.1，**反偷懒门**：如实报告异常路径数，若 < 2 → 解释或标 `@incomplete-coverage`；未解之谜 ≥ 3 条；不强制但少于此数需说明。

**变体 D 扫描流程**（Aggregate）：
1. 通读全部上游资产（不是摘要）→ 2. 提取关键数据点 → 3. 交叉一致性检查（entity 名 / 端点交集）→ 4. 综合非复制粘贴

### E. 编排者 Prompt 组装逻辑

**变量来源解析**：

| 变量 | 来源 |
|------|------|
| `${PROJECT_ROOT}` | Step 0 用户确认（`pwd` 或 `--path`）|
| `${SKILL_HOME}` | Skill 系统注入（当前 skill 安装位置）|
| `${SRC_DIR}` | Step 1 勘探推断（`src/main/java` 或 `src/`）|
| `${WEB_SRC}` | 前端源码目录（`src/web/` 或 `src/main/resources/static/`）|
| `${MODEL}` | `CLAUDE_CODE_MODEL` / 模型标识 |

**变体 → 资产映射表**：

| 资产 | 变体 | 模板文件 | 特殊参数 |
|:-:|:-:|---|---|
| 02 | A | `assets/02-数据模型与表结构.md.tmpl` | 无 DDL 时加 `--infer-mode` |
| 03 | A | `assets/03-后端-Controller接口清单.md.tmpl` | — |
| 04 | A | `assets/04-后端-Mapper操作清单.md.tmpl` | — |
| 06 | B | `assets/06-后端-安全认证.md.tmpl` | 强制 OWASP 10 项逐项回应 |
| 07/08/09 | A | 对应 `assets/0[789]-*.tmpl` | 纯后端跳过 |
| 05 | C | `assets/05-后端-服务与业务逻辑.md.tmpl` | 传入 Phase 1 的 03+04 路径 |
| 10 | C | `assets/10-业务流图.md.tmpl` | 传入 Phase 1+2 全部路径 |
| 11 | B | `assets/11-技术债与遗留项.md.tmpl` | 传入上游资产路径 |
| 13 | B | `assets/13-反模式扫描报告.md.tmpl` | 传入 `scan-antipatterns.sh` 结果 |
| 12 | D | `assets/12-修复建议与优先级.md.tmpl` | 传入 W-11 输出 |
| 01/00 | D | 01 用 `assets/01-系统总览.md.tmpl` | **编排者自己写**（不 spawn）|

**Worker Spawn 通用 Prompt 结构**：

```
【角色】你是 {变体} Worker，负责产出资产 {NN}-{资产名}.md
【5 铁律】{共享 Preamble §D}
【模板】Read: ${SKILL_HOME}/assets/{NN}-{模板}.md.tmpl
【prompt 参考】可选 Read: ${SKILL_HOME}/references/prompts/{NN}-{prompt}.md
{变体指令（§D 中 A/B/C/D 扫描流程）}
【项目信息】PROJECT_ROOT=${PROJECT_ROOT} SRC_DIR=${SRC_DIR} WEB_SRC=${WEB_SRC} 技术栈={Step 1 继承}
【Phase 1 共享事实】{项目规模 / 关键目录 / 已知警惕区域}
【输出要求】写入 ${PROJECT_ROOT}/asset-docs/{NN}-{资产名}.md；frontmatter 必填 id/version/last_updated/data_source/code_version/owner/ai_consumable；自检过变体清单；返回文件路径+行数+grep 数 vs 表格行数对比
【降级约束】源文件 > 200 个时优先核心包（排除 test/ 和 deprecated/）；单文件 Read > 500 行时 grep 定位 + Read 上下文 ±50 行；严禁压缩到跳过实体
```

**Sonnet 合并 worker**（1 worker = 多资产）prompt 结构：开头标注"你是 Extract Worker，负责 02+04"，内部按 `【资产 A: 02】+【资产 B: 04】` 分块，每块带变体指令和独立自检清单；**内部执行顺序**：先完成 A 全部（读→写→自检），再开始 B（避免模板字段混淆）。

### F. Phase 间交接机制

**共享事实字典**（编排者每个 Phase 完成后写 `asset-docs/.phase-facts.md`，仅本会话用，不入 git）：

```markdown
## Phase 1 完成 @ {timestamp}
- 02: {N} 个 entity，{M} 张表
- 03: {N} 个 Controller，{M} 个端点
- 04: {N} 个 Mapper 接口，{M} 条 SQL
- 06: {N} 个安全配置类，{M} 个公开端点
## 交叉一致性标记
- [ ] 02 entity 名与 03 Controller 引用一致？
- [ ] 03 端点总数与 06 public 端点交集合理？
```

后续 Phase 的 worker prompt 引用此文件作为基线。

**Context 检查点**（写入对话）：每个 Phase 完成后输出"X worker 中 Y 完成，Z 失败；最长 worker 耗时 A；context 剩余 B"。Phase 3（W-10）启动前检查 context < 30K → 提示用户"上下文紧张，建议新开会话"。

**降级检查点**：

| 节点 | 条件 | 动作 |
|------|------|------|
| Phase 1 → 2 | ≥ 3 worker 失败 | 清理 Phase 1 产出，降级 v3.0 |
| Phase 1 → 2 | 编排者 context < 50K | 输出已完成资产，提示新开会话 |
| Phase 2 → 3 | 编排者 context < 30K | 强制 checkpoint + 新开会话 |
| Phase 3 → 4 | W-10 失败 | 编排者自己串行补 W-10（不全量降级）|

### G. 容错与降级

**Worker 失败处理**：

| 场景 | 处理 |
|------|------|
| Spawn 失败 | 重试 1 次，仍失败 → 编排者自己串行补 |
| 自检不通过 | 编排者发回修订指令，重跑 1 次 |
| 完整度比 < 0.80（预期 50 实写 35）| 返回补充 |
| 产出文件不存在 | 编排者自己串行补 |
| 审计 Agent FAIL | 该变体类型全部产出拒绝，编排者串行补该类型 |
| Phase 1 失败 ≥ 3/7 | **全量降级 v3.0**（多 agent 不可靠）|

**孤立端点检测**：Phase 1 完成后，编排者 grep 是否有 Controller 端点未被 03/06 任一资产引用 → 发现 → 两篇资产都返回补充。

**全量降级条件**（任一成立 → 退出 v3.5 走 v3.0）：

1. Phase 1 失败 ≥ 3/7 worker
2. 编排者 context < 20K（Step 1+2 后）
3. 项目 < 1 万行
4. 用户显式指定 `--mode=v3`

### H. 并行特有缺陷模式（4 种）

| 缺陷 | 描述 | 缓解 |
|------|------|------|
| **命名空间推断冲突** | W-02 称 `UserEntity`，W-03 看到 `User` 引用自行推断为不同 entity | W-02 共享事实字典收录 entity 全限定名；W-03/05/10 prompt 标"entity 名以 W-02 为准" |
| **推断发散** | W-05 和 W-10 对同一 `if (status==3)` 推断不同业务含义 | W-10 prompt 标"对照 W-05 业务规则，不一致标出/UNCERTAIN"；`check-consistency.sh` 校验 05 与 10 状态值交集 |
| **引用衰减** | W-10 读 W-02 表格时丢失字段级精度 | W-10 prompt 标"对每个引用 entity，Read 源 Entity 类确认字段名" |
| **模板解释漂移** | 不同 worker 对"说明"列含义理解不一致 | 共享事实字典附带"模板字段解释示例"（Step 1 提取 1-2 个正例）|

### I. 审计流程

**结构审计**（Phase 4 后、01/00 之前）：
1. `bash check-all.sh`（4 子脚本）
2. 交叉一致性：02 entity 名在 03/05/10 中拼写一致 / 12 修复 ID 全部映射到 11 位置 / 01 数字一览与实际各资产计数一致

**语义审计**（spawn 1 个审计 Agent 挑 3 篇反向读代码）：
- 必选 1 篇 Synthesize（05 或 10）— 幻觉风险最高
- 必选 1 篇 Analyze（06 或 11）— 漏扫风险最高
- 随机 1 篇 Extract（02/03/04/07/08/09 任一）— Phase 1 输入基础

**审计学科 Prompt**（违规 = 审计作废）：
```
1. 你只能验证，不能重写资产。发现错误标记，不要修复
2. 每条评分必有 Read 证据。说"与代码矛盾"必须引用源码片段
3. 不确定时标 UNCERTAIN，不要猜测。UNCERTAIN 不扣分
4. 你没发现错误 ≠ 资产正确。你只证明抽样位置没错
5. 不要因"看起来合理"给 PASS。PASS 要求源码逐字对照一致
```

**审计门禁**：
- 0 FAIL → 通过
- 1-2 MAJOR → 该篇返回 worker 修订
- ≥1 FAIL → 该变体类型全部产出拒绝
- ≥3 MINOR → 该篇返回 worker 修订

**审计覆盖率诚实声明**：3/14 = 21% 采样（高风险样本），不能推广到未审计的 79%。未被审计的资产标 `audit_status: unaudited`，供人类 reviewer 优先检查。

### J. 质量机制对比（v3.0 → v3.5）

| v3.0 机制 | v3.5 状态 | 替代机制 |
|-----------|---------|---------|
| 串行依赖排序 | 保留 | Phase 管线（§C）|
| 共享上下文一致性 | 削弱 | 共享事实字典（§F）+ `check-consistency.sh` |
| 人类抽查 5-10 端点 | 加强 → 8-12 | 并行引入新错误类型（命名空间冲突等）|
| 同行校验 | 不变 | 同行校验 |
| 业务流人工走读 1-2 流 | 加强 → 2-3 流 | W-10 冷启动追踪调用链比串行同一 agent 记忆更不可靠 |

**质量等价性诚实声明**：v3.5 不声称并行质量 ≥ 串行（无证据），但能**检测到**大部分质量退化，并在发现时触发修订。最终质量取决于修订循环执行力。Gate 3（人工对比 02/03/10 并行 vs 串行版）是最终裁决者。

### K. Worker 完成度指标（防空洞产出）

| 指标 | 阈值 | 不达标动作 |
|------|------|---------|
| **完整度比** | ≥ 0.95 | < 0.95 → 返回 worker 补充 |
| **证据密度** | Extract ≥ 0.30 / Analyze ≥ 0.50 / Synthesize ≥ 0.40 | 低于 → 审计 Agent 重点检查 |
| **自检通过率** | = 1.0 | < 1.0 → 返回 worker 修订（附未通过项清单）|

### L. Go/No-Go 门（实施前必过）

| Gate | 验证 | 通过 | 失败 |
|------|------|------|------|
| **Gate 1** | Agent 工具 `run_in_background` / `subagent_type` / `model` 参数可调；1 个 worker 端到端跑通 | 可用 | 放弃 v3.5，v3.0 是答案 |
| **Gate 2** | wxcbrc 跑 3 次对比 wall time | 并行 ≤ 串行 | 放弃（开销 > 收益）|
| **Gate 3** | 人工对比 02/03/10 并行 vs 串行 | 主观等价或更好 | 修订 worker prompt 再测 |

### M. 已知局限

| 局限 | 接受原因 |
|------|---------|
| `run_in_background` 行为未实测 | Gate 1 专测，不通过则终止 |
| 铁律 4-5 无法硬验证 | v3.0 同样不可；v3.5 通过强制最小量 + 审计抽查增软约束 |
| 并行可能比串行慢 | Gate 2 专测；小项目上加速比可能 < 1，大项目质量收益仍存 |
| 审计覆盖率 21% | 比 v3.0 0% 审计好；全量审计需人工，21% AI + 人工 review 是务实平衡 |

## 进度报告

每完成一步，输出一段进度报告：

```
=== Step 1/7 勘探 ===
✓ 找到入口：src/main/java/com/example/Application.java
✓ 技术栈：Java 17 + Spring Boot 3.2
✓ 项目规模：约 12 万行
→ 耗时：8 秒

=== Step 2/7 分类 ===
✓ 适用：全栈 Web 项目
→ 12 篇资产全部输出
→ 耗时：3 秒

=== Step 3/7 抽取 ===
✓ 12 篇资产生成完成（含 13-反模式扫描报告占位）
→ 耗时：1 分 12 秒

=== Step 4/7 校验 ===
✓ 自动校验：4/4 通过
✓ Swagger 缺位：已用 grep 双向对账
→ 耗时：25 秒

=== Step 5/7 标注 ===
✓ 11-技术债收 9 条 P0
✓ 13-反模式扫描报告：分布图 + 24 标签覆盖率
→ 耗时：40 秒

=== Step 6/7 派送 ===
✓ CLAUDE.md / CLAUDE-ASSET.md 已生成
✓ 接入 CI 配置建议
→ 耗时：15 秒

=== Step 7/7 回写 ===
✓ CI 配置写入 .github/workflows/docs-validate.yml
✓ 30 天告警机制就位
→ 耗时：5 秒
```

## 错误处理

| 错误 | 处理 |
|---|---|
| `${PROJECT_ROOT}` 不是有效目录 | 报告并停止 |
| 方法论文档找不到 | 报告并提示重新 install |
| AI 抽取出错 | 保留已有 + 跳过 + 报告（不阻断） |
| 校验脚本报错 | 列出问题但不阻断，给人工修复入口 |
| 用户中断 | 保存当前进度，下次继续 |
| 已有 asset-docs/ | 询问是否覆盖（CLI：自动跳过） |

## 重要约束

1. **路径处理**：
   - `${PROJECT_ROOT}` 来自 `--path` 参数或用户当前工作目录
   - 跨平台：使用 `${PROJECT_ROOT}` 而非硬编码 `/`
   - Windows 路径：脚本内部用 `cygpath` 转换（如 Git Bash 环境）

2. **方法论定位**：
   - 优先用 `${SKILL_HOME}`（skill 安装时记录的绝对路径）
   - 退化：从当前工作目录向上找 5 层

3. **资产输出位置**：
   - 严格 `${PROJECT_ROOT}/asset-docs/`
   - 不写 `${PROJECT_ROOT}/docs/`（避免与已有项目冲突）

4. **CLAUDE.md 双文件策略**：
   - `CLAUDE.md` ≤ 80 行（轻量索引 + "按需加载"标注）
   - `CLAUDE-ASSET.md` 详细（按需 Read）

5. **绝对禁止**：
   - 不写硬编码密钥/密码（用 `<REDACTED>`）
   - 不写自定义严重度（统一 P0-P3）
   - 不省元信息头
   - 不省 frontmatter（6 必填 + 2 可选：`id` / `version` / `last_updated` / `data_source` / `owner` / `ai_consumable` 为必填；`code_version` / `severity_taxonomy` 为可选；详见 `02-目录与命名规范.md §3`）
   - 不省强制列

## 附加资产（

skill 在 `${PROJECT_ROOT}/asset-docs/` 下生成的核心是 **12 篇编号资产**（00-12）。除此以外还有 **3 份附加资产**，按需使用：

| 附加资产 | 用途 | 何时使用 |
|---|---|---|
| `CHANGELOG.md` | 资产版本变更日志 | **始终生成**（init 脚本必建） |
| `CLAUDE.md.tmpl` | 轻量 AI 引导模板 | 跑 `write-claude-index.sh` 时被填充为 `${PROJECT_ROOT}/CLAUDE.md` |
| `CLAUDE-ASSET.md`（在用户项目根）| 12 篇资产详细清单 | 跑 `write-claude-asset.sh` 时生成到 `${PROJECT_ROOT}/CLAUDE-ASSET.md` |

> **CHANGELOG.md.tmpl** 留在 `${SKILL_HOME}/assets/`，不复制到用户项目（与 #2 决策一致）。
> **CLAUDE.md.tmpl** 由 init 脚本单独 cp 到 `${PROJECT_ROOT}/asset-docs/`，供用户在 `write-claude-index.sh` 跑前先调整。

## 输出完成报告

执行完 7 步法后输出：

```
═══════════════════════════════════════
  反向阅读完成（v2.2 · 7 步法）
═══════════════════════════════════════
✓ 目标项目：${PROJECT_ROOT}
✓ 资产输出：${PROJECT_ROOT}/asset-docs/
✓ 索引文件：${PROJECT_ROOT}/CLAUDE.md
✓ 详情文件：${PROJECT_ROOT}/CLAUDE-ASSET.md
✓ 12 篇资产：全部生成（含 13-反模式扫描报告占位）
✓ 校验：DOCS_DIR=${PROJECT_ROOT}/asset-docs bash ${SKILL_HOME}/scripts/check-all.sh
✓ 总耗时：X 分 Y 秒

下一步：
  1. 人工 review 关键资产
  2. 接入 CI（见 references/methodology.md §9，模板见 Step 7）
  3. 让 AI 写新功能：喂 01+02+03（最小集）
  4. 订阅 30 天 last_updated 告警
═══════════════════════════════════════
```

## 元信息

| 字段 | 值 |
|---|---|
| 配套 | references/methodology/*.md（9 篇方法论）|
| 安装 | SKILL.md 自包含（无独立 install 脚本） |
| 适用 | Claude Code 0.2+ / Cursor 0.30+ / Copilot Workspace |
