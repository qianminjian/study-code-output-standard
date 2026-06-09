#!/usr/bin/env bash
# init-validate.test.sh — 验证 init-asset-docs.sh 产出 12 篇资产
# 用法：bash tests/init-validate.test.sh
set -e

# 让 bash 算 glob 时不算字面 pattern（macOS BSD 兼容）
shopt -s nullglob

# 1. 准备临时目录
TEST_DIR="$(mktemp -d -t study-init-XXXXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 2. 跑 init
echo "[T1] init-asset-docs.sh 创建 12 篇资产"
bash "$REPO_ROOT/scripts/init-asset-docs.sh" "$TEST_DIR" </dev/null >/dev/null 2>&1
ASSET_DIR="$TEST_DIR/asset-docs"
[ -d "$ASSET_DIR" ] || { echo "FAIL: $ASSET_DIR 未创建"; exit 1; }
echo "  ✓ 资产目录已创建"

# 3. 验证 12 篇资产 00-12 全部产出
echo "[T2] 12 篇资产 00-12 全部产出"
MISSING=0
for n in 00 01 02 03 04 05 06 07 08 09 10 11 12; do
  if ! ls "$ASSET_DIR"/${n}-*.md >/dev/null 2>&1; then
    echo "  FAIL: 缺少 ${n}-*.md"
    MISSING=$((MISSING+1))
  fi
done
[ "$MISSING" = "0" ] || { echo "FAIL: $MISSING 个资产缺失"; exit 1; }
echo "  ✓ 00-12 全部产出"

# 4. 验证 scripts 5 份脚本存在且可执行
echo "[T3] scripts/ 5 份校验脚本存在"
for s in check-meta.sh check-severity.sh check-consistency.sh scan-antipatterns.sh validate-all.sh; do
  [ -f "$ASSET_DIR/scripts/$s" ] || { echo "FAIL: 缺少 $s"; exit 1; }
  [ -x "$ASSET_DIR/scripts/$s" ] || { echo "FAIL: $s 不可执行"; exit 1; }
done
echo "  ✓ 5 份脚本全部就位且可执行"

# 5. 验证 templates/ 13 份资产模板（00-12）+ 2 份特殊（CHANGELOG + CLAUDE）
echo "[T4] templates/ 13 份资产模板（00-12）"
TMPL_COUNT=$(ls "$ASSET_DIR/templates/"[0-9][0-9]-*.md.tmpl 2>/dev/null | wc -l | tr -d ' ')
EXPECTED=13
if [ "$TMPL_COUNT" != "$EXPECTED" ]; then
  printf 'FAIL: 资产模板数 %s，应为 %s\n' "$TMPL_COUNT" "$EXPECTED"
  exit 1
fi
printf '  ✓ %s 份资产模板（+ CHANGELOG + CLAUDE）\n' "$TMPL_COUNT"

# 5b. 验证 CHANGELOG 与 CLAUDE 模板也存在
[ -f "$ASSET_DIR/templates/CHANGELOG.md.tmpl" ] || { echo "FAIL: 缺 CHANGELOG.md.tmpl"; exit 1; }
[ -f "$ASSET_DIR/templates/CLAUDE.md.tmpl" ] || { echo "FAIL: 缺 CLAUDE.md.tmpl"; exit 1; }
echo "  ✓ CHANGELOG + CLAUDE 模板就位"

# 6. 验证 ai-prompts/ 13 份（含 00-全流程启动.md）
echo "[T5] ai-prompts/ 13 份 Prompt"
PROMPT_COUNT=$(ls "$ASSET_DIR/ai-prompts/"*.md 2>/dev/null | wc -l | tr -d ' ')
EXPECTED=13
if [ "$PROMPT_COUNT" != "$EXPECTED" ]; then
  printf 'FAIL: Prompt 数 %s，应为 %s\n' "$PROMPT_COUNT" "$EXPECTED"
  exit 1
fi
printf '  ✓ %s 份 Prompt\n' "$PROMPT_COUNT"

# 7. 验证 references/ 3 份
echo "[T6] references/ 3 份"
REF_COUNT=$(ls "$ASSET_DIR/references/"*.md 2>/dev/null | wc -l | tr -d ' ')
EXPECTED=3
if [ "$REF_COUNT" != "$EXPECTED" ]; then
  printf 'FAIL: references 数 %s，应为 %s\n' "$REF_COUNT" "$EXPECTED"
  exit 1
fi
printf '  ✓ %s 份 references\n' "$REF_COUNT"

# 8. 跑 check-meta.sh 应通过（12 篇资产 frontmatter 7 字段齐全）
echo "[T7] check-meta.sh 通过"
cd "$TEST_DIR"
DOCS_DIR="$ASSET_DIR" bash "$ASSET_DIR/scripts/check-meta.sh" >/dev/null 2>&1 || { echo "FAIL: check-meta.sh 报错"; cd - >/dev/null; exit 1; }
cd - >/dev/null
echo "  ✓ check-meta.sh 通过"

# 9. write-claude-asset.sh 12 篇资产全部缺失不报错（缺失行 —）
echo "[T8] write-claude-asset.sh 生成 CLAUDE-ASSET.md"
bash "$REPO_ROOT/scripts/write-claude-asset.sh" "$TEST_DIR" </dev/null >/dev/null 2>&1
if [ ! -f "$TEST_DIR/CLAUDE-ASSET.md" ]; then
  echo "FAIL: CLAUDE-ASSET.md 未生成"
  exit 1
fi
LINES=$(wc -l < "$TEST_DIR/CLAUDE-ASSET.md" | tr -d ' ')
printf '  ✓ CLAUDE-ASSET.md（%s 行）\n' "$LINES"

# 10. write-claude-index.sh 生成 CLAUDE.md（≤ 80 行）
echo "[T9] write-claude-index.sh 生成 CLAUDE.md（≤ 80 行）"
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
echo "==> init-validate.test.sh: 全部 9 项通过"
