#!/usr/bin/env bash
# init-asset-docs.sh — 在 ${PWD}/asset-docs/ 创建资产骨架
# 用法：bash init-asset-docs.sh [target-dir]
#   target-dir 默认 ${PWD}
#
# 效果：创建 ${TARGET}/asset-docs/ 含 12 篇资产 + 12 模板 + 12 Prompt + 5 脚本 + 1 索引
# 跨平台：Mac / Linux / Git Bash on Windows

set -e

# 0. 参数解析
TARGET="${1:-${PWD}}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"

# 1. 推断方法论根目录（通过脚本路径）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"

# 兼容 Git Bash on Windows（路径可能含 /c/...）
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
  # 退化方案：从当前工作目录向上找
  CUR="$(pwd)"
  for i in 1 2 3 4 5; do
    if [ -f "$CUR/docs/00-总览与方法论.md" ]; then
      SCRIPT_DIR="$CUR/docs/scripts"
      break
    fi
    CUR="$(dirname "$CUR")"
  done
fi

if [ -z "$SCRIPT_DIR" ] || [ ! -f "$SCRIPT_DIR/../../docs/00-总览与方法论.md" ]; then
  echo "ERROR: 无法定位方法论根目录"
  echo "  请通过 install.sh 安装后由 Claude Code 调用"
  exit 1
fi

METHODOLOGY_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="$TARGET/asset-docs"

echo "==> 方法论根目录: $METHODOLOGY_DIR"
echo "==> 资产输出目录: $OUTPUT_DIR"
echo ""

# 2. 检查目标目录
if [ ! -d "$TARGET" ]; then
  echo "ERROR: 目标目录不存在: $TARGET"
  exit 1
fi

# 3. 检测已有
if [ -d "$OUTPUT_DIR" ]; then
  echo "WARN: $OUTPUT_DIR 已存在"
  if [ -t 0 ]; then
    read -p "  是否覆盖？[y/N] " yn
    case "$yn" in
      [yY]*) rm -rf "$OUTPUT_DIR" ;;
      *) echo "已取消"; exit 1 ;;
    esac
  else
    # 非交互模式：保留已有
    echo "  非交互模式：保留已有内容，跳过"
    echo ""
    echo "==> 完成（已有 asset-docs/）"
    exit 0
  fi
fi

# 4. 创建目录结构
mkdir -p "$OUTPUT_DIR"/{templates,ai-prompts,references,scripts}

# 5. 复制 12 份资产占位（带 frontmatter）
# 修复 P2-01：白名单方式（仅复制 00-12 编号资产，跳过其它）
echo "==> 复制 12 份资产占位"
for n in 00 01 02 03 04 05 06 07 08 09 10 11 12; do
  # 用通配符找 0N-*.md.tmpl
  for tmpl in "$METHODOLOGY_DIR/docs/templates/${n}-"*.md.tmpl; do
    if [ -f "$tmpl" ]; then
      name="$(basename "$tmpl" .md.tmpl)"
      cp "$tmpl" "$OUTPUT_DIR/$name.md"
      echo "  + $name.md"
    fi
  done
done

# 6. 复制 templates/ 副本
echo "==> 复制 templates/"
cp -R "$METHODOLOGY_DIR/docs/templates/." "$OUTPUT_DIR/templates/"

# 7. 复制 ai-prompts/ 副本
echo "==> 复制 ai-prompts/"
cp -R "$METHODOLOGY_DIR/docs/ai-prompts/." "$OUTPUT_DIR/ai-prompts/"

# 8. 复制校验脚本
echo "==> 复制 scripts/"
for s in check-meta.sh check-severity.sh check-consistency.sh scan-antipatterns.sh validate-all.sh; do
  if [ -f "$METHODOLOGY_DIR/docs/scripts/$s" ]; then
    cp "$METHODOLOGY_DIR/docs/scripts/$s" "$OUTPUT_DIR/scripts/$s"
  fi
done
# 修复 P3-01：chmod 失败不吞错（set -e 已开启，失败会退出）
chmod +x "$OUTPUT_DIR/scripts/"*.sh

# 9. 复制 references/（方法论摘要）
echo "==> 复制 references/"
if [ -d "$METHODOLOGY_DIR/skill/references" ]; then
  cp -R "$METHODOLOGY_DIR/skill/references/." "$OUTPUT_DIR/references/"
fi

# 10. 创建资产变更日志
cat > "$OUTPUT_DIR/CHANGELOG.md" <<EOF
# Asset Docs Changelog

## [1.0.0] - $(date +%Y-%m-%d)
### 全部
- 初版：12 篇资产 + 12 模板 + 12 Prompt + 5 脚本 + 3 references
EOF

# 11. 创建资产说明 README
cat > "$OUTPUT_DIR/README.md" <<EOF
# Asset Docs — 反向阅读产出

> 由 \`study-code-output-standard\` skill 生成。
> 整理时间：$(date +%Y-%m-%d)
> 目标项目：$TARGET

## 目录结构

\`\`\`
asset-docs/
├── 00-文档索引.md
├── 01-系统总览.md
├── 02-数据模型与表结构.md
├── 03-后端-Controller接口清单.md
├── 04-后端-Mapper操作清单.md
├── 05-后端-服务与业务逻辑.md
├── 06-后端-安全认证.md
├── 07-前端-页面与组件清单.md
├── 08-前端-状态管理与路由.md
├── 09-静态前台.md
├── 10-业务流图.md
├── 11-技术债与遗留项.md
├── 12-修复建议与优先级.md
├── CHANGELOG.md
├── templates/      ← 12 份可填充模板
├── ai-prompts/     ← 12 份 AI Prompt
├── references/     ← 方法论摘要
└── scripts/        ← 5 个校验脚本
\`\`\`

## 校验

\`\`\`bash
bash scripts/validate-all.sh
\`\`\`

## AI 编程：按需喂入

| 任务 | 喂入 |
|---|---|
| CRUD | 01 + 02 + 03 |
| 重构 | + 05 + 11 |
| 修 P0 | + 11 + 12 |
| 完整 | 全部 12 篇 |
EOF

echo ""
echo "==> 完成！"
echo ""
echo "下一步："
echo "  1. 在 Claude Code 中调用 /study-code-output-standard 继续抽取"
echo "  2. 或手动填充各 .md 文件"
echo "  3. 跑 bash $OUTPUT_DIR/scripts/validate-all.sh 校验"
