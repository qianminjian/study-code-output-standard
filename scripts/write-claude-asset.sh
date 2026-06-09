#!/usr/bin/env bash
# write-claude-asset.sh — 写 ${TARGET}/CLAUDE-ASSET.md 资产详情
# 用法：bash write-claude-asset.sh [target-dir]
#
# 策略：CLAUDE-ASSET.md 是 12 篇资产的"详细地图"，按需 Read
#
# v2 修复（修 3 个 P0）：
# 1. grep -c 失败时不再产生多行字符串（用 ${var:-0} + 整数校验）
# 2. 不再使用 eval 拼接（改用临时文件 + 读取）
# 3. 缺失资产不显示死链（改用纯文字"缺失"）

set -e

TARGET="${1:-${PWD}}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"

PROJECT_NAME="$(basename "$TARGET")"
OUTPUT="$TARGET/CLAUDE-ASSET.md"
ASSET_DIR="$TARGET/asset-docs"

# 检测 asset-docs 是否存在
if [ ! -d "$ASSET_DIR" ]; then
  echo "WARN: $ASSET_DIR 不存在"
  echo "  请先运行 init-asset-docs.sh"
  exit 1
fi

# 检测已存在
if [ -f "$OUTPUT" ]; then
  if [ -t 0 ]; then
    read -p "  $OUTPUT 已存在，覆盖？[y/N] " yn
    case "$yn" in
      [yY]*) ;;
      *) echo "已跳过"; exit 0 ;;
    esac
  else
    echo "  $OUTPUT 已存在（非交互模式：跳过）"
    exit 0
  fi
fi

# 通用：安全地把 grep -c 输出转成纯整数（修 P0-01）
# 用法：safe_grep_count <pattern> <file>
safe_grep_count() {
  local result
  result=$(grep -c "$1" "$2" 2>/dev/null || true)
  # 取第一行（避免多行字符串）
  result=$(printf '%s\n' "$result" | head -1)
  # 整数校验
  case "$result" in
    ''|*[!0-9]*) echo 0 ;;
    *) echo "$result" ;;
  esac
}

# 扫 12 篇资产的实际状态
# 用临时文件存储结果，避免 eval 注入风险（修 P0-02）
TMPDIR_STATUS="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_STATUS"' EXIT

for n in 00 01 02 03 04 05 06 07 08 09 10 11 12 13; do
  STATUS_FILE="$TMPDIR_STATUS/${n}_status"
  NAME_FILE="$TMPDIR_STATUS/${n}_name"

  f=$(ls "$ASSET_DIR"/${n}-*.md 2>/dev/null | head -1)
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f" | tr -d ' ' | head -1)
    has_meta=$(safe_grep_count '@meta' "$f")
    has_placeholder=$(safe_grep_countE "$f" 2>/dev/null || safe_grep_count '<YYYY-MM-DD>' "$f")
    base="$(basename "$f" .md)"

    # 占位判定：有 meta 但有未替换占位符，或内容 < 30 行
    if [ "$has_placeholder" -gt 0 ] || [ "$lines" -lt 30 ] || [ "$has_meta" -eq 0 ]; then
      echo "占位" > "$STATUS_FILE"
    else
      echo "✓" > "$STATUS_FILE"
    fi
    echo "$base" > "$NAME_FILE"
  else
    echo "缺失" > "$STATUS_FILE"
    # 不写 NAME_FILE：缺失资产不显示链接（修 P0-03）
  fi
done

# 安全的 safe_grep_countE 备用（带 -E 的扩展正则）
safe_grep_countE() {
  local result
  result=$(grep -cE "$1" "$2" 2>/dev/null || true)
  result=$(printf '%s\n' "$result" | head -1)
  case "$result" in
    ''|*[!0-9]*) echo 0 ;;
    *) echo "$result" ;;
  esac
}

# 读取状态的辅助函数
read_status() { cat "$TMPDIR_STATUS/${1}_status" 2>/dev/null || echo "缺失"; }
read_name()   { cat "$TMPDIR_STATUS/${1}_name" 2>/dev/null; }

# 生成 CLAUDE-ASSET.md
{
  echo "# $PROJECT_NAME — 资产详情"
  echo
  echo "> **按需加载**：本文件是 13 篇资产的\"详细地图\"（v2.2 起加 13-反模式扫描报告）。"
  echo "> 配合 \`CLAUDE.md\`（轻量索引）使用。"
  echo "> 生成时间：$(date +%Y-%m-%d)"
  echo
  echo "---"
  echo
  echo "## 1. 资产清单（13 篇）"
  echo
  echo "| 编号 | 资产 | 状态 | 文件 |"
  echo "|:-:|---|:-:|---|"
  for n in 00 01 02 03 04 05 06 07 08 09 10 11 12 13; do
    s=$(read_status "$n")
    case "$n" in
      00) name="文档索引";;
      01) name="系统总览";;
      02) name="数据模型与表结构";;
      03) name="后端-Controller接口清单";;
      04) name="后端-Mapper操作清单";;
      05) name="后端-服务与业务逻辑";;
      06) name="后端-安全认证";;
      07) name="前端-页面与组件清单";;
      08) name="前端-状态管理与路由";;
      09) name="静态/多端";;
      10) name="业务流图（端到端）";;
      11) name="技术债与遗留项";;
      12) name="修复建议与优先级";;
      13) name="反模式扫描报告（v2.2 新增）";;
    esac
    # 缺失资产：状态显示，但文件列不显示链接（修 P0-03 死链）
    if [ "$s" = "缺失" ]; then
      echo "| $n | $name | 缺失 | — |"
    else
      file_name=$(read_name "$n")
      echo "| $n | $name | $s | [\`${file_name}.md\`](asset-docs/${file_name}.md) |"
    fi
  done
  echo
  echo "> 状态说明：✓ 已生成 / 占位 待填充 / 缺失 未生成"
  echo
  echo "---"
  echo
  echo "## 2. 资产-代码强引用关系"
  echo
  echo "> 任何修改必须保持这些引用关系一致。"
  echo
  echo "| 关系 | 检查方式 |"
  echo "|---|---|"
  echo "| 02 ↔ 03 | 03 提到 X 实体 → 02 必有 X 表 |"
  echo "| 02 ↔ 04 | 实体 ↔ Mapper |"
  echo "| 03 ↔ 05 | API ↔ Service |"
  echo "| 03 ↔ 06 | API ↔ 鉴权 |"
  echo "| 07 ↔ 08 | 组件 ↔ 状态/路由 |"
  echo "| 10 ↔ 02-09 | 业务流 ↔ 各层资产 |"
  echo "| 11 ↔ 02-10 | 技术债 ↔ 各层资产 |"
  echo "| 12 ↔ 11 | 修复建议 ↔ 技术债 |"
  echo "| 13 ↔ 11 | 反模式扫描 ↔ 技术债（13 是 11 的扫描数据源）|"
  echo
  echo "---"
  echo
  echo "## 3. AI 编程喂入策略"
  echo
  echo "| 任务 | 喂入 |"
  echo "|---|---|"
  echo "| 简单 CRUD | \`01\` + \`02\` + \`03\`（最小集） |"
  echo "| 重构 | + \`05\` + \`11\`（推荐集） |"
  echo "| 修 P0 | + \`11\` + \`12\` + \`13\`（含反模式分布） |"
  echo "| 完整 | 13 篇（可承担新功能/重构/修 Bug） |"
  echo
  echo "---"
  echo
  echo "## 4. 校验（v2.2 起 scripts/ 留在 SKILL_HOME）"
  echo
  echo '```bash'
  echo "bash \${SKILL_HOME}/scripts/check-all.sh"
  echo "# 向后兼容："
  echo "bash \${SKILL_HOME}/scripts/validate-all.sh"
  echo '```'
  echo
  echo "包含 4 类校验："
  echo "- \`check-meta.sh\` — 元信息头 6 必填 + 2 可选 + 30 天 last_updated 告警（v2.2 新增）"
  echo "- \`check-severity.sh\` — 严重度 P0-P3（P0>10 自动告警）"
  echo "- \`check-consistency.sh\` — 资产-代码一致性（端点 / Controller / Mapper 数对齐）"
  echo "- \`scan-antipatterns.sh\` — 反模式扫描（v2.3 满覆盖 24/24 标签）"
  echo
  echo "---"
  echo
  echo "## 5. CI 接入（v2.2 起 scripts/ 路径用 \${SKILL_HOME}）"
  echo
  echo '```yaml'
  echo "# .github/workflows/docs-validate.yml"
  echo "name: Docs Validate"
  echo "on:"
  echo "  pull_request:"
  echo "    paths:"
  echo "      - 'asset-docs/**'"
  echo "      - 'src/**'"
  echo "jobs:"
  echo "  validate:"
  echo "    runs-on: ubuntu-latest"
  echo "    steps:"
  echo "      - uses: actions/checkout@v4"
  echo "      - name: Run all checks"
  echo "        run: bash \$SKILL_HOME/scripts/check-all.sh"
  echo '```'
  echo
  echo "---"
  echo
  echo "## 6. 模板与 Prompt（v2.2 起留在 SKILL_HOME）"
  echo
  echo "- 模板：\`\${SKILL_HOME}/templates/\`（13 份 .md.tmpl，含 v2.2 新增 13-反模式扫描报告）"
  echo "- AI Prompt：\`\${SKILL_HOME}/ai-prompts/\`（13 份 .md，单点真源）"
  echo "- 反模式：\`\${SKILL_HOME}/references/anti-patterns.md\`（24 标签全集）"
  echo
  echo "---"
  echo
  echo "## 7. 元信息"
  echo
  echo "| 字段 | 值 |"
  echo "|---|---|"
  echo "| 项目 | $PROJECT_NAME |"
  echo "| 资产版本 | 1.0.0 |"
  echo "| 生成时间 | $(date +%Y-%m-%d) |"
  echo "| 配套 | \`asset-docs/\` + \`CLAUDE.md\` |"
} > "$OUTPUT"

# 清理临时文件
rm -rf "$TMPDIR_STATUS"
trap - EXIT

echo "✓ 写入: $OUTPUT"
echo "  策略：详细资产地图（按需 Read）"
