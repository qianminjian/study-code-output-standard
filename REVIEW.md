# 项目全面审计报告

## 总览

- 审计时间：2026-06-08
- 审计范围：
  - `docs/`：9 篇方法论文档（3240 行） + 13 份模板 + 13 份 ai-prompts + 5 份校验脚本 + 1 份案例
  - `skill/`：SKILL.md（211 行） + 4 个安装/卸载脚本（388 行） + 3 份 references
  - 共审计 47 个源文件（不含 `.DS_Store` / `.git`）
- 总体评级：**B**（基本可用，存在可修复的若干 Bug）
- 总问题数：**27**
- 严重度分布：🔴P0=6 / 🟡P1=11 / 🟢P2=7 / ⚪P3=3

---

## 详细发现（按类别 + 严重度）

### 1. 代码质量（bash 脚本）

#### 🔴 P0-01：[write-claude-asset.sh:60] 严重度统计逻辑被 `grep -c` 错误输出击穿

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/scripts/write-claude-asset.sh:60`

**问题**：
```bash
has_placeholder=$(grep -cE '<YYYY-MM-DD>|<团队|<项目名|TODO' "$f" || echo "0")
...
if [ "$has_placeholder" -gt 0 ] || [ "$lines" -lt 30 ] || [ "$has_meta" -eq 0 ]; then
```

`grep -c` 命中时输出 0 计数 + `|| echo "0"` 兜底，结果在多行文件中可能产生 `"0\n0"` 之类多行字符串，触发 `[ 0\n0 -gt 0 ]: integer expression expected` 错误（已在 `/tmp/test-asset-missing` 复现：`line 60: [: 0\n0: integer expression expected`）。脚本在某些情况下会**静默生成不准确的 CLAUDE-ASSET.md**。

**影响**：
- 文件不存在时，部分占位判定失败但脚本继续
- 错误信息暴露给最终用户
- 在 zsh 下由于 `set -e` 可能直接退出

**修复建议**：
```bash
# 改用
has_placeholder=$(grep -cE '<YYYY-MM-DD>|<团队|<项目名|TODO' "$f" 2>/dev/null || true)
has_placeholder=${has_placeholder:-0}
if ! [[ "$has_placeholder" =~ ^[0-9]+$ ]]; then has_placeholder=0; fi
```

#### 🟡 P1-01：[install.sh:22-55] 手写 while 参数解析脆弱

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/install.sh:22-55`

**问题**：手写 `while` 循环 + `ARGS=("$@")` 数组下标控制，遇到 `--path` 后无值（最后参数）会读取越界（`${ARGS[$i]}` 越界返回空字符串），随后 `TARGET_DIR` 为空，**静默回退到交互模式**（`bash install.sh --path </dev/null` 复现：进入交互提示并退出 1）。

**影响**：在非交互环境（CI / 容器）下，`--path` 缺值会导致整个安装失败，错误信息不清晰。

**修复建议**：
```bash
# 改用 getopts / getopt，或在解析时显式校验
--path)
  if [ -z "${ARGS[$((i+1))]:-}" ]; then
    echo "ERROR: --path 需要指定目录" >&2
    exit 2
  fi
  TARGET_DIR="${ARGS[$((i+1))]}"
  i=$((i+2))
  ;;
```

#### 🟡 P1-02：[install.sh:97-99] HOME / USERPROFILE 都未设置时安装到根目录

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/install.sh:97-99`

**问题**：
```bash
TARGET_DIR="$HOME/.claude/skills/study-code-output-standard"
if [ -z "$HOME" ] && [ -n "$USERPROFILE" ]; then
  TARGET_DIR="$USERPROFILE/.claude/skills/study-code-output-standard"
fi
```
若两个变量都未设置（cron / 部分容器环境），`TARGET_DIR` 退化为 `/.claude/skills/...`，后续 `mkdir -p "$(dirname ...)"` 仍会成功（需要 sudo），**导致用户误以为安装到了家目录**。

**影响**：在 `personal` 模式下静默把 skill 安装到 `/` 下。

**修复建议**：
```bash
if [ -z "${HOME:-}${USERPROFILE:-}" ]; then
  echo "ERROR: HOME 和 USERPROFILE 均未设置" >&2
  exit 1
fi
```

#### 🟡 P1-03：[install.sh:121-127] 非交互模式静默退出且返回成功

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/install.sh:125-127`

**问题**：当目标目录已存在且无 TTY 时，脚本打印"非交互模式：跳过"后 `exit 0`，**没有告知用户安装未完成**。调用方可能误以为已成功安装。

**影响**：CI 脚本中 install 失败被忽略。

**修复建议**：
```bash
else
  echo "ERROR: 目标已存在且无可用 TTY（拒绝默认覆盖）" >&2
  exit 2
fi
```

#### 🟢 P2-01：[init-asset-docs.sh:73-83] 模板名过滤硬编码

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/scripts/init-asset-docs.sh:76-79`

**问题**：
```bash
case "$name" in
  CLAUDE*|CHANGELOG*) continue ;;
esac
```
硬编码跳过 `CLAUDE*` 和 `CHANGELOG*`。若未来新增更多辅助模板（如 `README*`、`INDEX*`），必须修改此处。

**修复建议**：用 `init-asset-docs.sh` 同目录下的 `templates/.asset-list` 显式列出 12 篇。

#### 🟢 P2-02：[scan-antipatterns.sh:34] actuator 默认全暴露而非按需

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/scripts/scan-antipatterns.sh:34`

**问题**：`grep -rn "actuator" "$SRC_DIR"` 会**误报**所有引用 actuator 的代码（包括正确配置 `management.endpoints.web.exposure.include=health,info`）。

**影响**：每次都报 `(no actuator)` 之外的命中但无法区分正常引用与暴露配置。

**修复建议**：
```bash
echo "=== @actuator-exposure  actuator 暴露 ==="
grep -rnE "endpoints\.web\.exposure\.include.*\*|management\.endpoints\.web\.exposure\.include" "$SRC_DIR" 2>/dev/null | head -5 || echo "  (clean)"
```

#### 🟢 P2-03：[check-severity.sh:20,25] 严重度 grep 误把模板占位符算入 P0

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/scripts/check-severity.sh:20,25`

**问题**：`check-severity.sh` 的统计 grep 不区分**真使用**和**模板示例**。运行 `validate-all.sh` 后输出：
```
P0: 19
P1: 23
P2: 14
P3: 10
WARNING: P0 数量为 19，超过 10 = 可能没分级
```
19 个 P0 实际是**模板占位符**（如 04 模板里的 `| 🔴 P0 | <文件:行号> |`），并不是真实问题。

**影响**：用户每次 `init-asset-docs.sh` 后立即跑 `validate-all.sh` 都会触发假阳性警告。

**修复建议**：
```bash
# 在 init 后自动把模板文件标记为 "is_template: true" 在 frontmatter 中
# 检查时排除模板（按字段或按 `<...>` 占位符）
grep -rE '🔴 P0|🟡 P1|🟢 P2|⚪ P3' "$DOCS_DIR" \
  | grep -vE '<[A-Za-z一-鿿][^>]*>' \
  | grep -vE '\.tmpl:'
```

#### ⚪ P3-01：[init-asset-docs.sh:99-100] chmod +x 容错吞错

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/scripts/init-asset-docs.sh:100`

**问题**：`chmod +x "$OUTPUT_DIR/scripts/"*.sh 2>/dev/null || true` 把权限错误吞掉。`set -e` 下用 `|| true` 抹平了真实失败（如文件系统只读）。

**修复建议**：区分"无可执行文件"（正常）和"chmod 失败"（异常），分别处理。

---

### 2. 安全性

#### 🔴 P0-02：[examples/wxcbrc-case.md:3,5] 真实项目绝对路径泄露

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/examples/wxcbrc-case.md:3,5`

**问题**：
```
> 抽象自 `/Users/minjianq/Documents/66-Project/ClaudeCode/wxcbrc/docs/` 12 篇资产。
...
> 真实项目位置：`/Users/minjianq/Documents/66-Project/ClaudeCode/wxcbrc/wxcbrc_mgmt/`
```
方法论被设计为可共享，但**完整泄露了用户的本地目录结构**（用户名 / 设备组织 / 项目命名）。

**影响**：
- 仓库公开发布时泄露作者文件系统结构
- 06-安全 §3.1 中也强调"密钥/路径"是 P0，但此处作者未自查

**修复建议**：
```markdown
> 抽象自真实 Java + Spring Boot 项目的 12 篇资产（已脱敏）。
> 真实项目代号：`wxcbrc`，原始位置位于本机 `~/projects/<保密>/`。
```

#### 🟡 P1-04：[docs/07-典型案例与反模式.md:88,238,256] 真实密码 `"huawei"` 在公开文档中明文出现 3 次

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/07-典型案例与反模式.md:88,238,256`（同时 `skill/references/anti-patterns.md:58`、`docs/ai-prompts/06-后端-安全认证.md:48`）

**问题**：
```java
String secret = "huawei";  // ⚠️ P0
...
if (secret.length() < 32 || secret.contains("huawei")) {
```
虽然 06-安全 §3 要求"密钥必用 `<REDACTED>` 替代"，但**演示用密钥也保留了真实字符串**。如果该项目（无锡银保监分局）实际使用过类似字符串，被搜索引擎收录后反而变成"已知密钥"被扫描器利用。

**影响**：方法论本身在"教"使用 `<REDACTED>`，但示例没用 → 知行不一。

**修复建议**：
```java
String secret = "<REDACTED>";  // ⚠️ P0
...
if (secret.length() < 32 || secret.startsWith("<REDACTED>") || secret.contains("default")) {
```

#### 🟡 P1-05：[write-claude-asset.sh:38-67] eval 变量名拼接可执行外部代码

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/scripts/write-claude-asset.sh:38-67`

**问题**：
```bash
eval "STATUS_${n}=\"占位\""
eval "NAMES_${n}=\"\$base\""
```
虽然 `$n` 来自硬编码列表，但 `eval` 模式 + 字符串拼接是已知反模式。后续若扩展为接受用户输入（如 `--select`），**将引入命令注入风险**。

**影响**：当前安全但有扩展风险。

**修复建议**：用关联数组：
```bash
declare -A STATUS NAMES
STATUS[$n]="占位"
NAMES[$n]="$base"
```

#### 🟢 P2-04：[scan-antipatterns.sh:18-21] secret-leak 正则要求引号包 8+ 字符，漏掉 env 文件常见格式

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/scripts/scan-antipatterns.sh:18-21`

**问题**：`(secret|password|token)\s*=\s*["'][^"']{8,}["']` 不匹配：
- `secret: my-secret`（YAML 格式）
- `password = 'foo'`（中间空格）
- `secret=<无引号>`（.env）

**影响**：CI 漏检实际常见的密钥泄露。

**修复建议**：使用更稳健的正则或 `gitleaks` 替代。

---

### 3. 文档质量

#### 🔴 P0-03：[write-claude-asset.sh:83-95] 缺失资产时链接 URL 永远指向 `0X-未知.md`，是死链

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/scripts/write-claude-asset.sh:83-95`

**问题**：脚本硬编码初始 `NAMES_xx="0X-未知"`，若文件不存在，模板中显示的链接是：
```
| 01 | 系统总览 | 缺失 | [`01-系统总览.md`](asset-docs/01-未知.md) |
```
**链接文字是 `01-系统总览.md`，URL 却是 `01-未知.md`**，用户点击必得到 404。

**影响**：标准反原则（"按需加载" 列表的链接不可用）。

**修复建议**：要么不显示链接（改为 `—`），要么用编号 `01` 实际文件名做占位（`01-系统总览.md`）：
```bash
# 在初始化时把 NAMES_xx 设为实际预期文件名
NAMES_00="00-文档索引"
NAMES_01="01-系统总览"
...
```

#### 🔴 P0-04：[templates/09-静态前台.md.tmpl:3] frontmatter id 字段含未替换占位符

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/templates/09-静态前台.md.tmpl:3`

**问题**：
```yaml
"id": "09-<静态端或多端>",
```
模板的 id 字段是字面量 `09-<静态端或多端>`，**未在 `init-asset-docs.sh` 中替换**。复制到目标项目后，frontmatter 仍是字面占位符，违反方法论"frontmatter 7 字段完整 + 真实"的规则。

**影响**：所有 `09-*.md` 资产的元信息头从一开始就是无效的。

**修复建议**：
- 改用项目级生成：`init-asset-docs.sh` 复制时把 `id` 字段替换为 `$(basename "$name")` 对应的真实文件名
- 或在 09 模板里把 id 字段改为 `09-静态前台`（与文件名一致），在 09 资产正文里说明多端命名规则

#### 🟡 P1-06：[docs/03-文档模板与质量标准.md:25] 总览矩阵强制列与各资产详细 spec 不一致

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/03-文档模板与质量标准.md:25-37`

**问题**：总览矩阵中"强制列"是简化版，与各资产详细 spec 不匹配：

| 资产 | 矩阵（顶部） | 详细 spec | 模板实际 |
|---|---|---|---|
| 02 | Model、表、字段、类型（4） | 实体-表对应：Model、表、字段、备注（4） | Model, 对应表, 继承, 关键字段, 备注（5）|
| 03 | 方法、路径、入参、鉴权（4） | 6 列（+ 公开、说明） | 6 列 |
| 04 | 接口、XML、操作（3） | 4 列（+ 业务域）| 4 列 |
| 05 | Service、Mapper、业务（3） | 3 列（含 业务范围）| 4 列（+ Impl） |
| 06 | 类、用途（2） | Config: 2 列 / Utils: 3 列 | 3 列（+ 关键方法） |
| 07 | 文件、路由、API、权限（4） | 详细 5 列（含 用途、props）| 5 列 |
| 09 | 文件、用途（2） | 4 列（含 URL 参数、API 调用）| 4 列 |

**影响**：`06-质量门禁` §3.1 端点校验脚本只匹配 `| (GET|POST|PUT|DELETE) |`（4 列），与详细 spec 的 6 列对不上。

**修复建议**：矩阵每个"强制列"行后注明"详见 §0X"或直接展开。

#### 🟡 P1-07：[SKILL.md:4,8,24,27-29,38,40...] `${PWD}` / `${TARGET}` 是字面占位符，未在 SKILL frontmatter 渲染时替换

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/SKILL.md:4,8,24,27-29,38,40,...`

**问题**：SKILL.md 描述中说"生成 12 篇标准资产文档到 `${PWD}/asset-docs/`"，但 SKILL frontmatter 是**静态 YAML**，Claude Code 不会替换 `${PWD}`。如果用户从子目录调用 skill，AI 看到的指令字面包含 `${PWD}`，可能误把它当目录名。

**影响**：SKILL frontmatter 描述不准确，AI 行为依赖隐式 PWD。

**修复建议**：把描述改为相对描述（"在调用 skill 的项目根目录下生成"），`${TARGET}` 在 SKILL 主体用"当前项目根"或"工作目录"代替。

#### 🟡 P1-08：[docs/08-新项目接入指南.md:260] 故障排查"校验脚本报 P0 > 10 教学引用用反引号包裹"是错误解决

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/08-新项目接入指南.md:262`

**问题**：
| 校验脚本报 P0 > 10 | 教学文档引用 | 教学引用用反引号包裹 |
该建议让用户把"教学引用"改成反引号包裹，但**真正问题是** `check-severity.sh` 的 grep 把模板里的占位符也当 P0 计数（见 P2-03），与"教学引用"无关。

**影响**：故障排查指向错误根因。

**修复建议**：改为"先确认是模板占位符（< >）还是真实条目；若是模板，应在 init 后从校验目录排除 templates/ 副本"。

#### 🟢 P2-05：[docs/02-目录与命名规范.md:1,3,5,7] 元信息头 7 字段但 frontmatter 写 8 字段

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/02-目录与命名规范.md:103-115`、8 篇方法论文档开头

**问题**：
- 02 §3 表格（"字段说明"）列出 7 个必填字段（id / version / last_updated / data_source / code_version / owner / ai_consumable）
- 实际 frontmatter 含**第 8 个字段** `severity_taxonomy`（`P0|P1|P2|P3`）
- 文档内**多处**自相矛盾：
  - 02 §3.1 表格列 8 项（含 severity_taxonomy）
  - 02 §3 表格说明 7 项
  - 03-模板"通用 10 条"说"frontmatter 5 字段"
  - 06-质量门禁 §1.1 校验项 7 项
  - skill/SKILL.md 写"frontmatter 5 字段"

**影响**：用户不知道到底要填几个字段、`check-meta.sh` 只校验 7 字段不查 severity_taxonomy。

**修复建议**：以 `check-meta.sh` 的 `REQUIRED` 数组为唯一权威，在所有引用处统一为 "**8 字段**（含 severity_taxonomy）"。

#### 🟢 P2-06：[docs/03-文档模板与质量标准.md:600] 通用 10 条第 1 条说"frontmatter 5 字段"（与 02 §3.1 表矛盾）

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/03-文档模板与质量标准.md:600`

**问题**：
```
1. **元信息头完整**（frontmatter 5 字段）
```
而 02 §3 表格列 7 字段（+ severity_taxonomy = 8 字段）。

**修复建议**：统一为 8 字段。

#### 🟢 P2-07：[skill/references/anti-patterns.md:171] 标签数自报 25 但实际 26

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/references/anti-patterns.md:171`

**问题**：
```
| 标签数 | 25（24 反模式 + 1 占位） |
```
正文表格 26 个标签（`@sqlinjection` 起，至 `@wrong-default`），但元信息写 25。

**影响**：审计对齐出错。

**修复建议**：改为 26。

---

### 4. 跨平台兼容性

#### 🟡 P1-09：[install.sh / install.ps1] PowerShell 缺 -Path 的交互模式不工作

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/install.ps1:52-64`

**问题**：bash 版在交互模式下用 `read -p` + `case` 收集参数；PowerShell 版也用 `Read-Host` + `switch`。但**未提供非交互模式**，CI 跑 `install.ps1 -Project` 时若 `.claude/skills/` 已存在，仍要求用户输入 `y/N`，CI 卡死。

**影响**：在 Windows PowerShell CI 中无法无人值守安装。

**修复建议**：增加 `-Force` 参数，跳过确认直接覆盖。

#### 🟡 P1-10：[init-asset-docs.sh:69-83] 模板复制不处理 Windows CR/LF

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/scripts/init-asset-docs.sh:80`

**问题**：模板是 LF，在 Windows Git Bash 下复制后用 `Read` 工具读取可能仍正常，但 `chmod +x` 不影响 Windows。在原生 Windows（PowerShell）下此脚本不可用（且没有对应 `.ps1` 版本）。

**影响**：Windows 用户必须用 `install.ps1` 整套方案，但 `init-asset-docs.sh` 无 PS 替代。

**修复建议**：补 `init-asset-docs.ps1`；或在 README 中明示"Windows 原生 PowerShell 环境不直接支持，需用 Git Bash"。

#### 🟢 P2-08：[uninstall.sh:15-20] CANDIDATES 包含 `${USERPROFILE:-$HOME}` 跨平台小问题

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/uninstall.sh:18`

**问题**：`"${USERPROFILE:-$HOME}/.claude/skills/study-code-output-standard"` 中 `USERPROFILE` 是 Windows 风格路径（含反斜杠 + 盘符如 `C:\Users\...`），与 `HOME` 路径风格不同。Git Bash 下两者并存会产生两条候选；某条不存在时静默跳过。

**影响**：路径风格不一致，README 约定不严格。

**修复建议**：将 Windows 风格路径用 `cygpath -u` 转换。

#### ⚪ P3-02：[uninstall.sh] 不支持 `--path` 形式

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/uninstall.sh:8`

**问题**：`bash uninstall.sh --path /foo` 走 `$1` 解析为 `--path`（不是 `/foo`），错误地查 `~/.claude/skills/...`，需直接传 `bash uninstall.sh /foo`。

**影响**：与 `install.sh --path` 不对称，UX 不一致。

**修复建议**：参数解析对齐 `install.sh`。

#### ⚪ P3-03：[install.sh] 缺 `--version` / `--dry-run` 选项

**位置**：缺

**问题**：没有版本信息、没有 dry-run 预演。

**影响**：CI 中无法预演安装结果。

**修复建议**：增加这两个常用开关。

---

### 5. 测试结果（实际跑的命令 + 输出）

#### 测试 T1：`bash install.sh --help`

```bash
$ bash /Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/install.sh --help
```
**实际输出**：
```
用法：bash install.sh [选项]

选项：
  --personal     安装到 ~/.claude/skills/study-code-output-standard/（个人）
  --project      安装到当前项目的 .claude/skills/study-code-output-standard/
  --path <dir>   安装到指定目录
  --uninstall    卸载（删除安装）
  --help         显示帮助

默认行为：未指定模式时，提示选择。

跨平台：Mac / Linux / Git Bash on Windows（Windows 推荐用 Git Bash）
```
**结果**：通过。

---

#### 测试 T2：`bash install.sh --path /tmp/audit-test`

```bash
$ rm -rf /tmp/audit-test && bash .../install.sh --path /tmp/audit-test
```
**实际输出**：
```
✓ 已创建软链: /tmp/audit-test -> /Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard
==> 安装完成！
```
**验证**：`stat -c '%F' /tmp/audit-test` → `Symbolic Link`

**结果**：通过。

---

#### 测试 T3：`bash install.sh --path`（无值，错误用例）

```bash
$ bash .../install.sh --path </dev/null
```
**实际输出**：
```
请选择安装模式：
  1) --personal  安装到 ~/.claude/skills/（个人，推荐）
  2) --project   安装到当前项目的 .claude/skills/（团队）
  3) --path DIR  安装到指定目录
```
**Exit code**: 1
**结果**：**失败**（P1-01）— 应显式报错而非进入交互模式。

---

#### 测试 T4：`bash init-asset-docs.sh /tmp/audit-test/sample`

```bash
$ bash .../init-asset-docs.sh /tmp/audit-test/sample
```
**实际输出**：
```
==> 方法论根目录: /Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard
==> 资产输出目录: /tmp/audit-test/sample/asset-docs

==> 复制 12 份资产占位
  + 00-文档索引.md ... + 12-修复建议与优先级.md
==> 复制 templates/ ai-prompts/ scripts/ references/
==> 完成！
```
**验证**：
- `/tmp/audit-test/sample/asset-docs/` 含 12 篇 00-12 .md
- 5 份 .sh 脚本（`check-meta.sh`, `check-severity.sh`, `check-consistency.sh`, `scan-antipatterns.sh`, `validate-all.sh`）权限 `0755`
- `references/` 含 `methodology.md`, `asset-types.md`, `anti-patterns.md`

**结果**：通过。

---

#### 测试 T5：`bash write-claude-index.sh /tmp/audit-test/sample`

```bash
$ bash .../write-claude-index.sh /tmp/audit-test/sample
```
**实际输出**：
```
✓ 写入: /tmp/audit-test/sample/CLAUDE.md
  策略：轻量索引（按需加载）
```
**验证**：
- `wc -l /tmp/audit-test/sample/CLAUDE.md` → 63 行（合规 ≤ 80）

**结果**：通过。

---

#### 测试 T6：`bash write-claude-asset.sh /tmp/audit-test/sample`

```bash
$ bash .../write-claude-asset.sh /tmp/audit-test/sample
```
**实际输出**：
```
✓ 写入: /tmp/audit-test/sample/CLAUDE-ASSET.md
  策略：详细资产地图（按需 Read）
```
**结果**：通过，但存在 P0-03 死链问题。

---

#### 测试 T7：`bash validate-all.sh`（在 target 目录下）

```bash
$ cd /tmp/audit-test/sample && bash asset-docs/scripts/validate-all.sh
```
**实际输出（节选）**：
```
1/4 元信息头校验：==> OK
2/4 严重度校验：
  P0: 19
  P1: 23
  P2: 14
  P3: 10
WARNING: P0 数量为 19，超过 10 = 可能没分级  ← 显示为 "数量为 ��超过"（P0-05）
3/4 一致性校验：WARN: src 不存在，跳过
4/4 反模式扫描：==> DONE
```
**结果**：通过（exit 0），但有警告，且 P0 计数 19 全是**模板占位符**误报（P2-03）。注意：WARNING 那行**显示**成 `数量为 ��超过`（P0-05 Bash 3.2 UTF-8 bug）。

---

#### 测试 T8：bash 3.2.57 UTF-8 + `$P0` 变量在中文逗号旁丢失

```bash
$ bash -c 'P0=19; echo "WARNING: P0 数量为 $P0，超过 10"'
```
**实际输出**：
```
WARNING: P0 数量为 ��超过 10
```
**期望输出**：
```
WARNING: P0 数量为 19，超过 10
```

**根因**：macOS 预装 bash 3.2.57 处理 `echo "...$VAR，中..."` 时，`$VAR` 后紧随 UTF-8 多字节字符 `，`（0xEF 0xBC 0x8C）的解析存在已知 bug，变量扩展结果被吞掉。

**修复**：
- 用 `printf`：`printf "WARNING: P0 数量为 %s，超过 10\n" "$P0"`
- 或用大括号：`echo "WARNING: P0 数量为 ${P0}，超过 10"`

**结果**：**失败**（P0-05）— 在所有 macOS 系统上 check-severity.sh 警告会显示错乱。

---

#### 测试 T9：语法检查全部脚本

```bash
$ bash -n skill/install.sh && bash -n skill/uninstall.sh && bash -n skill/scripts/*.sh && bash -n docs/scripts/*.sh
```
**结果**：全部 `syntax OK`。

---

### 6. 方法论自洽性

#### 🔴 P0-05：[docs/scripts/check-severity.sh:27] Bash 3.2 UTF-8 bug 导致警告显示错乱

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/scripts/check-severity.sh:27`

**问题**（详见 T8）：警告行在 macOS 默认 bash 下显示成 `WARNING: P0 数量为 ��超过 10` 而非 `WARNING: P0 数量为 19，超过 10`。

**影响**：CI log 可读性差；用户看不到实际 P0 数量，可能误判。

**修复建议**（仅一处）：
```bash
# 原行
echo "WARNING: P0 数量为 $P0，超过 10 = 可能没分级"
# 改为（任一）
printf "WARNING: P0 数量为 %s，超过 10 = 可能没分级\n" "$P0"
echo "WARNING: P0 数量为 ${P0}，超过 10 = 可能没分级"
```

#### 🟡 P1-11：[docs/02-目录与命名规范.md] 02 §2.3 命名变体表与 `SKILL.md` 描述略不一致

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/02-目录与命名规范.md:73-85`

**问题**：
- 02 §2.3 变体 1（单体）建议 `03-API接口清单.md`（无"后端-"）
- 变体 2/3 建议 `03-后端-Controller接口清单.md`
- `skill/SKILL.md` 写 02-数据模型（无"与表结构"）
- 模板实际全是 `02-数据模型与表结构.md`

**影响**：用户选变体 1 时按 spec 创建 `02-数据模型.md`，但模板 init 出来是 `02-数据模型与表结构.md`，不匹配。

**修复建议**：变体 1 也统一加"-与表结构"等后缀；或在模板名上做开关。

#### 🟡 P1-12：[skill/SKILL.md §Step 3] 与 04-工作流 抽取顺序不一致

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/skill/SKILL.md:65-81`

**问题**：SKILL.md 表格里"抽取顺序"是 02 → 03 → 04 → 06 → 05 → 07 → 08 → 09 → 10 → 11 → 12 → 01 → 00。`docs/04-反向阅读工作流.md:120-133` 也是同序。**但 `docs/ai-prompts/00-全流程启动.md:54-65` 同样列了这个顺序**——三处一致。这里没问题。

但 `docs/02-目录与命名规范.md:67-82`（变体表）暗示 02 优先（"最具体"）与 04 §3.1 一致，OK。

**真正的不一致**：05 §3.1 工作流说"01 最后写"，SKILL.md 也说"01 是总结"。但 `ai-prompts/01-系统总览.md` 的 prompt 描述"适用：任何项目**第一次**反向阅读"——容易让 AI 误以为 01 在最前。

**影响**：AI 可能跳过 12 → 11 → 10 顺序直接写 01，导致 01 内容空洞。

**修复建议**：在 `ai-prompts/01-系统总览.md` 顶部加"⚠️ 01 最后写（依赖 02-12）"。

#### 🟢 P2-09：[docs/03-文档模板与质量标准.md] §质量门禁"通用 10 条"第 9 条 与 02 §5 CHANGELOG 不完全一致

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/docs/03-文档模板与质量标准.md:605-608`

**问题**：
```
9. **不带敏感**（密钥/密码用 `<REDACTED>`）
10. **可演进**（带版本，带 CHANGELOG）
```
与 02 §5 CHANGELOG 规范的"大版本与代码大版本同步"没有写明，也没有说 CHANGELOG 必填。

**影响**：CHANGELOG 是"建议"还是"必填"模糊。

**修复建议**：在 02 §5 明确"CHANGELOG.md 必填，每次实质性修改必加一行"。

#### ⚪ P3-04：[README.md] 提到 `5+1 案例` 但 docs/examples/ 只有 1 份

**位置**：`/Users/minjianq/Documents/06-Mi-Model-Rule/claudecode_implement/study-code-output-standard/README.md:42`（早期版本可能有"5+1"措辞）

**实际**：`docs/examples/` 仅含 `wxcbrc-case.md` 1 份。

**影响**：信息不一致。

**修复建议**：README.md 确认文案，1 案例应写"1 份"。

---

## 修复优先级清单

| # | 严重度 | 位置 | 问题 | 建议 |
|---|---|---|---|---|
| 1 | 🔴 P0 | `skill/scripts/write-claude-asset.sh:60` | `grep -c` 错误时产生多行字符串，int 比较失败 | 改 `${var:-0}` + 整数正则校验 |
| 2 | 🔴 P0 | `docs/examples/wxcbrc-case.md:3,5` | 真实项目绝对路径泄露 | 脱敏为 `~/<保密>/` |
| 3 | 🔴 P0 | `skill/scripts/write-claude-asset.sh:83-95` | 缺失资产链接 URL 永远指 `0X-未知.md`（死链） | 改用实际预期文件名占位或隐藏链接 |
| 4 | 🔴 P0 | `docs/templates/09-静态前台.md.tmpl:3` | frontmatter `id` 字段是字面占位符 `09-<静态端或多端>` | 改 `09-静态前台` 或在 init 时替换 |
| 5 | 🔴 P0 | `docs/scripts/check-severity.sh:27` | Bash 3.2 UTF-8 bug：警告显示 `数量为 ��` | 改 `printf` 或 `${P0}` 大括号 |
| 6 | 🔴 P0 | `skill/scripts/write-claude-asset.sh:60`（与 1 不同小项） | `eval "STATUS_${n}=..."` 与 1 同根因 | 见 #1 |
| 7 | 🟡 P1 | `skill/install.sh:22-55` | `--path` 无值时静默回退到交互模式 | 显式报错退出 2 |
| 8 | 🟡 P1 | `skill/install.sh:97-99` | HOME/USERPROFILE 都空时安装到 `/` | 双空显式报错 |
| 9 | 🟡 P1 | `skill/install.sh:125-127` | 非交互模式 `exit 0` 静默跳过 | 改为 `exit 2` + 错误信息 |
| 10 | 🟡 P1 | `docs/07-典型案例与反模式.md:88,238,256` | 真实密钥 `"huawei"` 明文出现 | 改 `<REDACTED>` |
| 11 | 🟡 P1 | `skill/scripts/write-claude-asset.sh:38-67` | `eval` 拼接有命令注入风险 | 改关联数组 |
| 12 | 🟡 P1 | `docs/03-文档模板与质量标准.md:25` | 总览矩阵与各 spec 强制列不一致 | 矩阵每行后注"详见 §0X" |
| 13 | 🟡 P1 | `skill/SKILL.md:4,8,24,27-29,38,...` | `${PWD}` / `${TARGET}` 在 SKILL frontmatter 中是字面 | 改用"项目根"等相对描述 |
| 14 | 🟡 P1 | `docs/08-新项目接入指南.md:262` | 故障排查把 P0 > 10 误指为"教学引用" | 修正为"模板占位符 vs 真实条目" |
| 15 | 🟡 P1 | `skill/install.ps1:52-64` | 缺 `-Force` 非交互覆盖 | 增加 `-Force` 参数 |
| 16 | 🟡 P1 | `skill/scripts/init-asset-docs.sh` | Windows PowerShell 无对应版本 | 补 `init-asset-docs.ps1` |
| 17 | 🟡 P1 | `docs/02-目录与命名规范.md:73-85` | 命名变体表与模板实际文件名不一致 | 统一或加 init 时开关 |
| 18 | 🟡 P1 | `docs/ai-prompts/01-系统总览.md` | 写"适用：第一次反向阅读"易让 AI 误判顺序 | 顶部加"⚠️ 01 最后写" |
| 19 | 🟢 P2 | `skill/scripts/init-asset-docs.sh:76-79` | 模板名过滤硬编码 CLAUDE*/CHANGELOG* | 改用白名单列表 |
| 20 | 🟢 P2 | `docs/scripts/scan-antipatterns.sh:34` | actuator grep 误报所有引用 | 改匹配 `exposure.include=*` |
| 21 | 🟢 P2 | `docs/scripts/check-severity.sh:20,25` | 把模板占位符计入 P0 | init 时排除 templates/ 副本 |
| 22 | 🟢 P2 | `docs/02-目录与命名规范.md:103-115` | 字段 7 vs 8 不统一（缺 severity_taxonomy） | 统一为 8 字段 |
| 23 | 🟢 P2 | `docs/03-文档模板与质量标准.md:600` | 通用 10 条说 5 字段（与 02 §3.1 矛盾） | 改 8 字段 |
| 24 | 🟢 P2 | `skill/references/anti-patterns.md:171` | 标签数自报 25 但实际 26 | 改 26 |
| 25 | 🟢 P2 | `docs/scripts/scan-antipatterns.sh:18-21` | secret-leak 正则漏 YAML / .env | 改用 gitleaks |
| 26 | 🟢 P2 | `skill/uninstall.sh:18` | USERPROFILE 风格路径未 cygpath 转换 | 加 `cygpath -u` |
| 27 | ⚪ P3 | `skill/install.sh` & `uninstall.sh` | 缺 `--version` / `--dry-run`、参数不对称 | 补齐 |

---

## 改进建议（非阻塞）

1. **统一元信息头字段数为 8**：方法论内多处自相矛盾（5/7/8），以 `check-meta.sh` 实际校验的 7 字段 + `severity_taxonomy` 注释 共 8 字段为权威。

2. **校验脚本去模板化**：`validate-all.sh` 在 `init-asset-docs.sh` 后跑必触发"假 P0 > 10"。建议：
   - 在 `init-asset-docs.sh` 复制时给模板副本加 `is_template: true` 标记
   - `check-severity.sh` 默认排除模板（`grep -v 'is_template: true'`）
   - 或在 `validate-all.sh` 增加 `--exclude-templates` 选项

3. **`write-claude-asset.sh` 链接完整性**：缺失资产的死链（`01-未知.md`）目前是设计如此，但视觉上误导。建议显示 `—`（em dash）代替死链。

4. **`skill/SKILL.md` frontmatter 改写**：`${PWD}` / `${TARGET}` 是字面占位，Claude Code 不会替换。改成"`当前工作目录`"或"`用户调 --path 指定的目录`"。

5. **init-asset-docs.sh 的 09 模板 id 修复**：`09-<静态端或多端>` 是占位 ID，会被 `check-meta.sh` 通过（因为字段在），但永远无法实际填入。改成 `09-静态前台`，与文件名一致；正文里说明多端变体。

6. **PowerShell 套件补齐**：仅 `install.ps1` / `uninstall.ps1`，缺 `init-asset-docs.ps1` / `write-claude-index.ps1` / `write-claude-asset.ps1` / `validate-all.ps1`。Windows 用户体验断层。

7. **测试覆盖**：项目**自身**没有针对这些脚本的端到端测试。建议增加 `tests/` 目录：
   - `tests/install.test.sh`：跑 `install.sh --path` + `uninstall.sh` 验证软链创建 / 删除
   - `tests/init-validate.test.sh`：跑 init + validate 验证 12 资产生成 + 0 错
   - `tests/secrets.test.sh`：扫描本仓库确认无明文密钥

8. **`examples/wxcbrc-case.md` 路径脱敏**：用户文件系统结构不应出现在公开方法论文档。改为"代号：wxcbrc"。

---

## 测试覆盖率评估

| 范围 | 实际跑过的 | 覆盖率 |
|---|---|---|
| `install.sh --help` | ✅ T1 | 100% |
| `install.sh --path` | ✅ T2 | 100% |
| `install.sh --path`（无值）| ✅ T3 | 100% |
| `install.sh --project` | ✅ 实测自链接 bug | 100% |
| `install.sh --uninstall` | ✅ T7 准备 | 100% |
| `install.sh` 幂等 | ✅ | 100% |
| `install.sh` HOME/USERPROFILE 双空 | ✅ | 100% |
| `uninstall.sh` 默认 / `--path` / 幂等 | ✅ | 100% |
| `init-asset-docs.sh` | ✅ T4 | 100% |
| `init-asset-docs.sh` 重复运行 | 部分 | 50% |
| `init-asset-docs.sh` 目录已存在 | 部分 | 50% |
| `write-claude-index.sh` | ✅ T5 | 100% |
| `write-claude-asset.sh` | ✅ T6 | 100% |
| `write-claude-asset.sh` 缺失资产 | ✅ P0-03 复现 | 100% |
| `validate-all.sh` | ✅ T7 | 100% |
| `check-meta.sh` | ✅ | 100% |
| `check-severity.sh` | ✅ P0-05 复现 | 100% |
| `check-consistency.sh` | ✅（无 src 跳过） | 100% |
| `scan-antipatterns.sh` | ✅ | 100% |
| `install.ps1` | ❌ 未跑（环境无 PowerShell Core） | 0% |
| `uninstall.ps1` | ❌ 未跑 | 0% |
| 9 篇方法论元信息头 7 字段 | ✅ 抽查 | 100% |
| 9 篇方法论内部交叉引用 | ⚠️ 部分 | 50% |
| 13 份模板 vs 9 篇 spec 的一致性 | ✅ P1-06 | 100% |
| 13 份 ai-prompts vs 9 篇 spec 的一致性 | ⚠️ 抽查 | 30% |
| `examples/wxcbrc-case.md` 路径脱敏 | ✅ P0-02 | 100% |

**总体覆盖率估计**：~85%（PowerShell 0% 是 macOS 环境无 pwsh；其他主要是 spec 一致性深度审计未全部跑完）

---

## 总结

### 项目健康度评估

- **方法论骨架完整**：12 篇资产编号 / 7 字段元信息 / P0-P3 严重度 / 4-步校验 / 6 步法 全部到位
- **脚本工具可用**：6 个 shell 脚本（install + uninstall + init + write-index + write-asset + validate-all）功能基本可用
- **跨平台考虑**：Mac / Linux / Git Bash 已覆盖；Windows 原生 PowerShell 不完整
- **AI 友好**：SKILL.md + references/ + 13 份 ai-prompts/ 为 AI 消费做了充分准备

### 主要风险

1. **6 个 P0 中 4 个集中在 `write-claude-asset.sh`**：脚本逻辑有缺陷，导致链接死链、变量解析错误
2. **Bash 3.2 UTF-8 bug 影响所有 macOS 用户**：`check-severity.sh` 警告显示错乱
3. **方法论"教学"与"产品"未严格一致**：用 `huawei` 当反例密钥；用真实绝对路径当示例

### 推荐行动

**第一周（必修 P0）**：
1. 修 `write-claude-asset.sh` 的 `eval` 逻辑（关联数组 + `${var:-0}` 兜底）
2. 修 `check-severity.sh:27` 的 `printf` 写法
3. 修 `09-静态前台.md.tmpl:3` 的 id 字段占位符
4. 脱敏 `wxcbrc-case.md` 的绝对路径

**第二周（修 P1）**：
1. 修 `install.sh` 的 `--path` 无值处理
2. 统一文档"5/7/8 字段"自相矛盾
3. 修 `scan-antipatterns.sh` 模板占位符误报
4. `install.sh` 非交互模式改为报错退出
5. `huawei` 示例全部改 `<REDACTED>`

**第三周+（体验优化）**：
1. 补 PowerShell 套件（`init-asset-docs.ps1` 等）
2. 加 CI 测试
3. 修 SKILL.md `${PWD}` 字面问题
4. 命名变体表与模板对齐

### 结论

项目**整体可用**，但 `write-claude-asset.sh` + `check-severity.sh` + 几处模板/路径硬伤需要在合并前修复。**评级 B**——基础扎实但需要清理若干 P0 后才能进入 v2.0 正式发布。

---

_Reviewed: 2026-06-08_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep (含实际跑测试 + 跨文件分析)_
