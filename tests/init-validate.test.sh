#!/usr/bin/env bash
# init-validate.test.sh — 验证 init-asset-docs.sh 产出 13 篇资产占位
# 用法：bash tests/init-validate.test.sh
#
# v3.0: init 不再复制 scripts/templates/prompts/references 到用户项目
# 这些资源留在 SKILL_HOME，AI 通过 SKILL.md 引用路径直接读取
set -e

shopt -s nullglob

# 1. 准备临时目录
TEST_DIR="$(mktemp -d -t study-init-XXXXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 2. 跑 init
echo "[T1] init-asset-docs.sh 创建 asset-docs/"
bash "$REPO_ROOT/scripts/init-asset-docs.sh" "$TEST_DIR" </dev/null >/dev/null 2>&1
ASSET_DIR="$TEST_DIR/asset-docs"
[ -d "$ASSET_DIR" ] || { echo "FAIL: $ASSET_DIR 未创建"; exit 1; }
echo "  ✓ 资产目录已创建"

# 3. 验证 13 篇资产 00-13 全部产出（含 13-反模式扫描报告）
echo "[T2] 13 篇资产 00-13 全部产出"
MISSING=0
for n in 00 01 02 03 04 05 06 07 08 09 10 11 12 13; do
  if ! ls "$ASSET_DIR"/${n}-*.md >/dev/null 2>&1; then
    echo "  FAIL: 缺少 ${n}-*.md"
    MISSING=$((MISSING+1))
  fi
done
[ "$MISSING" = "0" ] || { echo "FAIL: $MISSING 个资产缺失"; exit 1; }
echo "  ✓ 00-13 全部产出"

# 4. 验证附加资产：CLAUDE.md.tmpl
echo "[T3] CLAUDE.md.tmpl 存在"
[ -f "$ASSET_DIR/CLAUDE.md.tmpl" ] || { echo "FAIL: 缺 CLAUDE.md.tmpl"; exit 1; }
echo "  ✓ CLAUDE.md.tmpl 就位"

# 5. 验证 CHANGELOG.md
echo "[T4] CHANGELOG.md 存在"
[ -f "$ASSET_DIR/CHANGELOG.md" ] || { echo "FAIL: 缺 CHANGELOG.md"; exit 1; }
echo "  ✓ CHANGELOG.md 就位"

# 6. 验证 .asset-docs.lock 保护锁
echo "[T5] .asset-docs.lock 存在"
[ -f "$ASSET_DIR/.asset-docs.lock" ] || { echo "FAIL: 缺 .asset-docs.lock"; exit 1; }
echo "  ✓ 资产保护锁就位"

# 7. 重复 init 应被 lock 拦截（非交互模式）
echo "[T6] 重复 init 被 lock 拦截"
bash "$REPO_ROOT/scripts/init-asset-docs.sh" "$TEST_DIR" </dev/null >/dev/null 2>&1 && { echo "FAIL: 应被 lock 拦截但未拦截"; exit 1; }
echo "  ✓ 资产保护锁生效"

# 8. write-claude-asset.sh 生成 CLAUDE-ASSET.md
echo "[T7] write-claude-asset.sh 生成 CLAUDE-ASSET.md"
bash "$REPO_ROOT/scripts/write-claude-asset.sh" "$TEST_DIR" </dev/null >/dev/null 2>&1
if [ ! -f "$TEST_DIR/CLAUDE-ASSET.md" ]; then
  echo "FAIL: CLAUDE-ASSET.md 未生成"
  exit 1
fi
LINES=$(wc -l < "$TEST_DIR/CLAUDE-ASSET.md" | tr -d ' ')
printf '  ✓ CLAUDE-ASSET.md（%s 行）\n' "$LINES"

# 9. write-claude-index.sh 生成 CLAUDE.md（≤ 80 行）
echo "[T8] write-claude-index.sh 生成 CLAUDE.md（≤ 80 行）"
bash "$REPO_ROOT/scripts/write-claude-index.sh" "$TEST_DIR" </dev/null >/dev/null 2>&1
if [ ! -f "$TEST_DIR/CLAUDE.md" ]; then
  echo "FAIL: CLAUDE.md 未生成"
  exit 1
fi
LINES=$(wc -l < "$TEST_DIR/CLAUDE.md" | tr -d ' ')
if [ "$LINES" -gt 80 ]; then
  printf 'FAIL: CLAUDE.md %s 行 > 80\n' "$LINES"
  exit 1
fi
printf '  ✓ CLAUDE.md（%s 行，≤ 80）\n' "$LINES"

echo ""
echo "==> init-validate.test.sh: 全部 8 项通过"
