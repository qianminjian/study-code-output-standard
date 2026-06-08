#!/usr/bin/env bash
# write-claude-asset.sh — 写 ${TARGET}/CLAUDE-ASSET.md 资产详情
# 用法：bash write-claude-asset.sh [target-dir]
#
# 策略：CLAUDE-ASSET.md 是 12 篇资产的"详细地图"，按需 Read

set -e

TARGET="${1:-${PWD}}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"

PROJECT_NAME="$(basename "$TARGET")"
OUTPUT="$TARGET/CLAUDE-ASSET.md"
ASSET_DIR="$TARGET/asset-docs"

# 检测 asset-docs 是否存在
if [ ! -d "$ASSET_DIR" ]; then
  echo "WARN: $ASSET_DIR 不存在"
  echo "  请先运行 write-claude-asset.sh 之前跑 init-asset-docs.sh"
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

# 扫 12 篇资产的实际状态
STATUS_00="缺失"; NAMES_00="00-未知"
STATUS_01="缺失"; NAMES_01="01-未知"
STATUS_02="缺失"; NAMES_02="02-未知"
STATUS_03="缺失"; NAMES_03="03-未知"
STATUS_04="缺失"; NAMES_04="04-未知"
STATUS_05="缺失"; NAMES_05="05-未知"
STATUS_06="缺失"; NAMES_06="06-未知"
STATUS_07="缺失"; NAMES_07="07-未知"
STATUS_08="缺失"; NAMES_08="08-未知"
STATUS_09="缺失"; NAMES_09="09-未知"
STATUS_10="缺失"; NAMES_10="10-未知"
STATUS_11="缺失"; NAMES_11="11-未知"
STATUS_12="缺失"; NAMES_12="12-未知"

for n in 00 01 02 03 04 05 06 07 08 09 10 11 12; do
  f=$(ls "$ASSET_DIR"/${n}-*.md 2>/dev/null | head -1)
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f" | tr -d ' ')
    has_meta=$(grep -c '@meta' "$f" || echo "0")
    has_placeholder=$(grep -cE '<YYYY-MM-DD>|<团队|<项目名|TODO' "$f" || echo "0")
    base="$(basename "$f" .md)"
    # 占位判定：有 meta 但有未替换占位符，或内容 < 30 行
    if [ "$has_placeholder" -gt 0 ] || [ "$lines" -lt 30 ] || [ "$has_meta" -eq 0 ]; then
      eval "STATUS_${n}=\"占位\""
    else
      eval "STATUS_${n}=\"✓\""
    fi
    eval "NAMES_${n}=\"\$base\""
  fi
done

# 生成 CLAUDE-ASSET.md
cat > "$OUTPUT" <<EOF
# $PROJECT_NAME — 资产详情

> **按需加载**：本文件是 12 篇资产的"详细地图"。
> 配合 \`CLAUDE.md\`（轻量索引）使用。
> 生成时间：$(date +%Y-%m-%d)

---

## 1. 资产清单（12 篇）

| 编号 | 资产 | 状态 | 文件 |
|:-:|---|:-:|---|
| 00 | 文档索引 | ${STATUS_00} | [\`00-文档索引.md\`](asset-docs/${NAMES_00}.md) |
| 01 | 系统总览 | ${STATUS_01} | [\`01-系统总览.md\`](asset-docs/${NAMES_01}.md) |
| 02 | 数据模型与表结构 | ${STATUS_02} | [\`02-数据模型与表结构.md\`](asset-docs/${NAMES_02}.md) |
| 03 | 后端-Controller接口清单 | ${STATUS_03} | [\`03-后端-Controller接口清单.md\`](asset-docs/${NAMES_03}.md) |
| 04 | 后端-Mapper操作清单 | ${STATUS_04} | [\`04-后端-Mapper操作清单.md\`](asset-docs/${NAMES_04}.md) |
| 05 | 后端-服务与业务逻辑 | ${STATUS_05} | [\`05-后端-服务与业务逻辑.md\`](asset-docs/${NAMES_05}.md) |
| 06 | 后端-安全认证 | ${STATUS_06} | [\`06-后端-安全认证.md\`](asset-docs/${NAMES_06}.md) |
| 07 | 前端-页面与组件清单 | ${STATUS_07} | [\`07-前端-页面与组件清单.md\`](asset-docs/${NAMES_07}.md) |
| 08 | 前端-状态管理与路由 | ${STATUS_08} | [\`08-前端-状态管理与路由.md\`](asset-docs/${NAMES_08}.md) |
| 09 | 静态/多端 | ${STATUS_09} | [\`09-静态前台.md\`](asset-docs/${NAMES_09}.md) |
| 10 | 业务流图（端到端） | ${STATUS_10} | [\`10-业务流图.md\`](asset-docs/${NAMES_10}.md) |
| 11 | 技术债与遗留项 | ${STATUS_11} | [\`11-技术债与遗留项.md\`](asset-docs/${NAMES_11}.md) |
| 12 | 修复建议与优先级 | ${STATUS_12} | [\`12-修复建议与优先级.md\`](asset-docs/${NAMES_12}.md) |

> 状态说明：✓ 已生成 / 占位 待填充 / 缺失 未生成

---

## 2. 资产-代码强引用关系

> 任何修改必须保持这些引用关系一致。

| 关系 | 检查方式 |
|---|---|
| 02 ↔ 03 | 03 提到 X 实体 → 02 必有 X 表 |
| 02 ↔ 04 | 实体 ↔ Mapper |
| 03 ↔ 05 | API ↔ Service |
| 03 ↔ 06 | API ↔ 鉴权 |
| 07 ↔ 08 | 组件 ↔ 状态/路由 |
| 10 ↔ 02-09 | 业务流 ↔ 各层资产 |
| 11 ↔ 02-10 | 技术债 ↔ 各层资产 |
| 12 ↔ 11 | 修复建议 ↔ 技术债 |

---

## 3. AI 编程喂入策略

| 任务 | 喂入 |
|---|---|
| 简单 CRUD | \`01\` + \`02\` + \`03\`（最小集） |
| 重构 | + \`05\` + \`11\`（推荐集） |
| 修 P0 | + \`11\` + \`12\` |
| 完整 | 12 篇（可承担新功能/重构/修 Bug） |

---

## 4. 校验

\`\`\`bash
bash asset-docs/scripts/validate-all.sh
\`\`\`

包含 5 类校验：
- \`check-meta.sh\` — 元信息头 7 字段
- \`check-severity.sh\` — 严重度 P0-P3
- \`check-consistency.sh\` — 资产-代码一致性
- \`scan-antipatterns.sh\` — 反模式扫描
- \`validate-all.sh\` — 一键跑全部

---

## 5. CI 接入

\`\`\`yaml
# .github/workflows/docs-validate.yml
name: Docs Validate
on:
  pull_request:
    paths:
      - 'asset-docs/**'
      - 'src/**'
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run all checks
        run: bash asset-docs/scripts/validate-all.sh
\`\`\`

---

## 6. 模板与 Prompt

- 模板：\`asset-docs/templates/\`（12 份 .md.tmpl）
- AI Prompt：\`asset-docs/ai-prompts/\`（12 份 .md）

---

## 7. 元信息

| 字段 | 值 |
|---|---|
| 项目 | $PROJECT_NAME |
| 资产版本 | 1.0.0 |
| 生成时间 | $(date +%Y-%m-%d) |
| 配套 | \`asset-docs/\` + \`CLAUDE.md\` |
EOF

echo "✓ 写入: $OUTPUT"
echo "  策略：详细资产地图（按需 Read）"
