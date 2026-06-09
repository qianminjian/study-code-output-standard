#!/usr/bin/env bash
# write-claude-index.sh — 写 ${TARGET}/CLAUDE.md 轻量索引
# 用法：bash write-claude-index.sh [target-dir]
#
# 策略：CLAUDE.md ≤ 80 行，标注"按需加载 CLAUDE-ASSET.md"
#
# 1. 引用路径全改 ${SKILL_HOME}  scripts/ assets/ references/prompts/ references/ 全部在 SKILL_HOME）
# 2. 加 13-反模式扫描报告到必读/AI 编程喂入列表

set -e

TARGET="${1:-${PWD}}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"

# 推断项目名（默认用目录名）
PROJECT_NAME="$(basename "$TARGET")"

OUTPUT="$TARGET/CLAUDE.md"

# 检测是否已存在
if [ -f "$OUTPUT" ]; then
  if [ -t 0 ]; then
    read -p "  $OUTPUT 已存在，覆盖？[y/N] " yn
    case "$yn" in
      [yY]*) ;;
      *) echo "已跳过"; exit 0 ;;
    esac
  else
    # 非交互模式：保留已有
    echo "  $OUTPUT 已存在（非交互模式：跳过）"
    exit 0
  fi
fi

cat > "$OUTPUT" <<EOF
# $PROJECT_NAME — AI 引导（索引）

> 本文件是**轻量索引**（80 行内），按需加载。
> 完整资产清单见 \`CLAUDE-ASSET.md\`，反向阅读产出见 \`asset-docs/\`。

## 必读资产（按角色）

| 角色 | 先读 |
|---|---|
| 接手新人 | \`asset-docs/00-文档索引.md\` → \`01-系统总览.md\` → \`02-数据模型与表结构.md\` |
| 写新功能 | \`02-数据模型与表结构\` + \`03-后端-Controller接口清单\` + \`05-后端-服务与业务逻辑\` |
| 修 Bug | \`11-技术债与遗留项\` + \`12-修复建议与优先级\` + \`13-反模式扫描报告\` + \`10-业务流图\` |
| AI 编程 | 喂 \`01+02+03\`（最小集）或 \`+05+11\`（推荐集）或 \`+13\`（含反模式）|

## 项目约束

<!-- TODO: 编辑此段，描述项目特定约束 -->

## 工作流

### 反向阅读（一次性）
\`\`\`bash
# 在 Claude Code 中调用：
/study-code-output-standard
\`\`\`

### 校验资产  scripts/ 留在 SKILL_HOME）
\`\`\`bash
# 推荐：v2.2 新名
bash \${SKILL_HOME}/scripts/check-all.sh
# 向后兼容：v2.0 老名（shim 自动转 check-all.sh）
bash \${SKILL_HOME}/scripts/validate-all.sh
\`\`\`

### 喂 AI 写代码
\`\`\`
请按 asset-docs/01-系统总览.md、02-数据模型与表结构.md、03-后端-Controller接口清单.md
的规范，实现 XXX 接口。
\`\`\`

## 按需加载（v2.2 路径 · scripts/ assets/ references/prompts/ references/ 全部在 \${SKILL_HOME}）

| 需要看 | 加载文件 |
|---|---|
| 13 篇资产详细清单 | \`CLAUDE-ASSET.md\` |
| 单篇资产详情 | \`asset-docs/<NN>-<name>.md\` |
| 模板（仅供 review，不复制到用户项目）| \`\${SKILL_HOME}/assets/<NN>-<name>.md.tmpl\` |
| AI Prompt（单点真源）| \`\${SKILL_HOME}/references/prompts/<NN>-<name>.md\` |
| 方法论 | \`\${SKILL_HOME}/references/methodology.md\` |
| 资产类型 | \`\${SKILL_HOME}/references/asset-types.md\` |
| 反模式 | \`\${SKILL_HOME}/references/anti-patterns.md\` |
| 校验脚本 | \`\${SKILL_HOME}/scripts/check-all.sh\` |

> **⚠️ v2.2 重要变更**：\`asset-docs/assets/\`、\`asset-docs/references/prompts/\`、\`asset-docs/scripts/\`、\`asset-docs/references/\` 4 个目录**不再复制到用户项目**。所有这些内容都在 \${SKILL_HOME}（约 \`~/.claude/skills/study-code-output-standard/\`）下。

## 反模式禁止（来自 11-技术债 + 13-反模式扫描报告）

- ❌ 硬编码密钥/密码
- ❌ SQL 字符串拼接 \`\${}\`
- ❌ CORS \`allowedOrigins("*")\`
- ❌ 明文传输密码
- ❌ 复制粘贴 perms
- ❌ AOP 切点路径写错（永远不触发）

## 元信息

| 字段 | 值 |
|---|---|
| 项目 | $PROJECT_NAME |
| 资产版本 | 1.0.0 |
| 整理时间 | $(date +%Y-%m-%d) |
EOF

echo "✓ 写入: $OUTPUT"
echo "  策略：轻量索引（按需加载）"
