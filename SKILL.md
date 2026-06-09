---
name: study-code-output-standard
description: |
  反向阅读任意代码项目，按"study-code-output-standard"方法论生成 12 篇标准资产文档到项目根目录的 asset-docs/。
  触发场景：用户说"反向阅读"、"提炼资产"、"分析项目结构"、"输出项目文档"、"code2docs"、"reformat this project"、"深度思考后提炼资产"等；亦可由深度思考 slash-command 触发：`/ttt`、`/ts`、`/tp`、`/tt`、`/tttt` 加上"提炼资产"作为动作目标。
  适用：任何规模的 全栈 / 后端 / 前端 / 多端 项目（1 万行+）。
  不适用：1-2 周 Demo、纯文档项目、单一库/SDK。
  输出：项目根目录/asset-docs/（12 篇资产 + 1 CHANGELOG + 1 README + 1 CLAUDE.md.tmpl，模板/prompt/脚本留在 skill 目录）。
---

# Skill: study-code-output-standard

> **路径约定**（v2.2 改用 shell 风格占位符，避免误读为可执行变量）：
> - `${PROJECT_ROOT}` = 用户调用 skill 时所在的项目根目录（默认 `pwd`）
> - `${SPECIFIED_PROJECT}` = 用户用 `--path <path>` 显式指定的项目目录
> - `${SKILL_HOME}` = 本 skill 安装位置（即仓库根目录，安装后是 `~/.claude/skills/study-code-output-standard/`）
> - **本 skill v2.1 起采用扁平布局**：SKILL.md、scripts/、references/、templates/、ai-prompts/、methodology/ 都在 `${SKILL_HOME}` 下
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

## ai-prompts/ 实际使用（v2.4 重新定位 · 本轮 #6）

> v2.4 起**明确定位**，避免与 templates/ @prompt 引用块重复：

| 资源 | 谁读 | 用途 |
|---|---|---|
| **`${SKILL_HOME}/templates/<NN>-*.md.tmpl`** | **AI 实际读取** | 含 `@prompt:` 引用块 + frontmatter + 占位结构 → AI 严格按模板写资产 |
| **`${SKILL_HOME}/ai-prompts/<NN>-*.md`** | **人类维护者 review** | AI 写资产时的"灵感库 / 完整 prompt 参考"，人类维护时 audit 写出质量 |
| **`${SKILL_HOME}/methodology/04-反向阅读工作流.md`** | 人类 + AI 共同 | 6→7 步法详细方法论 |
| **`${SKILL_HOME}/references/anti-patterns.md`** | 人类 + AI 共同 | 24 个反模式标签扫法 + 老朋友 5 案例 |

> **⚠️ 重要工作流**（v2.4 本轮 #6 修正）：
> - ❌ **不要**让 AI 直接读 `ai-prompts/` 目录生成资产——本轮测试发现实际**没用上**（设计意图 vs 实际使用脱节）
> - ✅ **应该**让 AI 读 `templates/<NN>-*.md.tmpl`（含 @prompt 引用块 + 完整骨架）
> - ✅ `ai-prompts/` 保留作为人类维护者的"prompt 灵感库"——review AI 写出时对照
> - 单点真源原则：模板维护时**同步刷** `ai-prompts/<NN>-*.md`（注释提示）

## 老系统快速通道（v2.4 新增 · 本轮 #5）

> 适用：jQuery 1.x / 无 DDL / 无 Swagger / 无 git / 无 README / 上古前后端分离站（如 wxcbrc）

5 步走完：

1. **Step 1 勘探必做**：`git init` + 首次 commit（无 git 时主动初始化）
2. **02 必启用 §2-B 推断模式**——所有表加 ⚠️，元信息标"DDL 来源：无（推断）"
3. **03 摘要表 "Swagger 启用"列填"否"** + 取消 Swagger 校对（Step 4 用 grep 双向对账）
4. **06 必加 11 项 OWASP 清单**——高亮 4 个 P0（@sqlinjection / @cors-wildcard / @actuator-exposure / @wrong-token-hdr）
5. **09 静态 + jQuery 检测**：global.js baseUrl 硬编码 / `$.html()` XSS 风险

> 详细降级矩阵见 `references/asset-types.md` "老旧系统"分支

## 写路径验证（v2.4 新增 · 本轮 #7）

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

**Skill 自身保护**（v2.4 本轮 #1）：
- init 脚本写 `.asset-docs.lock` 文件锁——重复 init 会被拦截
- 删除 lock 或加 `--force` 强制覆盖

## Token 预算（v2.4 新增 · 本轮 #2）

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
> - 中项目（1-10 万行）：**强烈建议分 4 阶段**，每阶段人类 review（详见 methodology/04 §分批工作流）
> - 大项目（> 10 万行）：**必须分批**，单次 LLM 上下文会爆
> - **每篇写完立即 `head -3 asset-docs/02-数据模型与表结构.md` 验证 @meta + 文件名一致**（避免路径错 silent 失败）

## 目标行为

用户在 `${PROJECT_ROOT}`（或 `${SPECIFIED_PROJECT}`）下，调用本 skill 后：

1. **自动按 7 步法执行反向阅读（v2.2 新增 Step 7·回写）**（勘探→分类→抽取→校验→标注→派送）
2. **输出到 `${PROJECT_ROOT}/asset-docs/`**
3. **生成 `${PROJECT_ROOT}/CLAUDE.md`**（轻量索引，**按需加载**）
4. **生成 `${PROJECT_ROOT}/CLAUDE-ASSET.md`**（资产详情，**按需加载**）

## 7 步法执行流程

### Step 0 · 启动确认（v2.2 新增 · Claude Code 中）

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
- Read: `${SKILL_HOME}/references/asset-types.md`
- 套用适用矩阵，决定 12 篇哪些输出 / 哪些占位 / 哪些省略
- 不适用也保留编号（如纯后端项目 07/08/09 写"本项目无前端"）

**输出**：12 篇覆盖决策表

### Step 3 · 抽取（Extraction）— AI 主战场

**目标**：生成 12 篇资产初稿

**必做动作**：

1. Bash: `bash ${SKILL_HOME}/scripts/init-asset-docs.sh ${PROJECT_ROOT}`
   - 效果：创建 `${PROJECT_ROOT}/asset-docs/` 骨架

2. 按 04-工作流 §3.1 的依赖顺序，逐个生成：

| 顺序 | 资产 | Prompt 文件 |
|:-:|---|---|
| 1 | 02-数据模型与表结构 | `${PROJECT_ROOT}/asset-docs/ai-prompts/02-数据模型与表结构.md` |
| 2 | 03-API 清单 | `${PROJECT_ROOT}/asset-docs/ai-prompts/03-后端-Controller接口清单.md` |
| 3 | 04-Mapper 清单 | `${PROJECT_ROOT}/asset-docs/ai-prompts/04-后端-Mapper操作清单.md` |
| 4 | 06-安全认证 | `${PROJECT_ROOT}/asset-docs/ai-prompts/06-后端-安全认证.md` |
| 5 | 05-服务与业务 | `${PROJECT_ROOT}/asset-docs/ai-prompts/05-后端-服务与业务逻辑.md` |
| 6 | 07-前端页面（如适用）| `${PROJECT_ROOT}/asset-docs/ai-prompts/07-前端-页面与组件清单.md` |
| 7 | 08-前端状态（如适用）| `${PROJECT_ROOT}/asset-docs/ai-prompts/08-前端-状态管理与路由.md` |
| 8 | 09-静态/多端（如适用）| `${PROJECT_ROOT}/asset-docs/ai-prompts/09-静态前台.md` |
| 9 | 10-业务流图 | `${PROJECT_ROOT}/asset-docs/ai-prompts/10-业务流图.md` |
| 10 | 11-技术债 | `${PROJECT_ROOT}/asset-docs/ai-prompts/11-技术债与遗留项.md` |
| 11 | 12-修复建议 | `${PROJECT_ROOT}/asset-docs/ai-prompts/12-修复建议与优先级.md` |
| 12 | 01-系统总览 | `${PROJECT_ROOT}/asset-docs/ai-prompts/01-系统总览.md` |
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
- Bash: `DOCS_DIR=${PROJECT_ROOT}/asset-docs bash ${SKILL_HOME}/scripts/check-all.sh`
  - v2.2 起 scripts 留在 `${SKILL_HOME}`（不再复制到用户项目，避免污染）
  - 向后兼容：老 `validate-all.sh` shim 仍可调，自动转 `check-all.sh`
  - **v2.3 起** `check-all.sh` 不再静默报"全部校验通过"——子脚本 `exit 1` 会显式标 `==> 校验完成：N 个步骤失败`
- 修复脚本报告的所有错误

> ⚠️ **必须人工抽样 5-10 个端点 + 3-5 个业务流**，否则视为半成品——脚本只发现候选名单，最终正确性靠人。

- 抽 5-10 个端点对照 Swagger / Postman 验证（人工）

**⚠️ 无 Swagger / Postman 时的替代校验**（v2.2 新增）：

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
2. Read: `${SKILL_HOME}/references/anti-patterns.md`
3. 把扫出的反模式**分别落到两份资产**：
   - **`11-技术债与遗留项.md`**：只收"**影响业务且有修复方案**"的反模式（如 @sqlinjection / @secret-leak / @cors-wildcard）
   - **`13-反模式扫描报告.md`（v2.2 新增）**：收"**模式分布 / 扫法 / 降级建议**"，按 24 个标签分类，含统计与风险雷达
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
   - `check-meta.sh` 每日检查 12 篇 `last_updated` 距今 > 30 天 → 告警（v2.2 新增）
   - 不阻断 PR，但要求 owner 在合并前刷新

4. **版本对齐**：
   - 代码 bump 大版本（v2 → v3）→ 资产同步 bump（同步改 12 篇 `version` + CHANGELOG）
   - 季度：资产 review，重排严重度

**退出条件**：
- CI 接入完成（PR 必跑 `check-all.sh`）
- `last_updated` 30 天告警机制就位
- 团队 owner 接受"改代码 = 改资产"SLA

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

## 附加资产（v2.2 新增段 · #12 修复）

skill 在 `${PROJECT_ROOT}/asset-docs/` 下生成的核心是 **12 篇编号资产**（00-12）。除此以外还有 **3 份附加资产**，按需使用：

| 附加资产 | 用途 | 何时使用 |
|---|---|---|
| `CHANGELOG.md` | 资产版本变更日志 | **始终生成**（init 脚本必建） |
| `CLAUDE.md.tmpl` | 轻量 AI 引导模板 | 跑 `write-claude-index.sh` 时被填充为 `${PROJECT_ROOT}/CLAUDE.md` |
| `CLAUDE-ASSET.md`（在用户项目根）| 12 篇资产详细清单 | 跑 `write-claude-asset.sh` 时生成到 `${PROJECT_ROOT}/CLAUDE-ASSET.md` |

> **CHANGELOG.md.tmpl** 留在 `${SKILL_HOME}/templates/`，不复制到用户项目（与 #2 决策一致）。
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
| 配套 | references/{methodology,asset-types,anti-patterns}.md |
| 安装 | install.sh (Mac/Linux) / install.ps1 (Windows) |
| 适用 | Claude Code 0.2+ / Cursor 0.30+ / Copilot Workspace |
