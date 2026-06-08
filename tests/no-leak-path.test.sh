#!/usr/bin/env bash
# no-leak-path.test.sh — 扫描本仓库，确保无 /Users/minjianq 等真实绝对路径泄露
# 用法：bash tests/no-leak-path.test.sh
#
# 背景：REVIEW.md P0-02 发现 docs/examples/wxcbrc-case.md 曾泄露 /Users/minjianq/... 真实路径
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 1. 扫描全仓（除 .git/、tests/、审计报告、历史 prompt）无 /Users/minjianq 路径
# 排除以下文件（这些是审计/历史/原始 prompt，路径出现是合理的）：
#   - REVIEW.md（审计报告本身）
#   - 输出代码资产的提示词.md（项目原始 prompt）
echo "[T1] 扫描 /Users/minjianq 真实路径泄露"
LEAKED=$(grep -rn "/Users/minjianq" "$REPO_ROOT" \
  --exclude-dir=".git" --exclude-dir="tests" --exclude-dir="node_modules" \
  --include="*.md" --include="*.sh" --include="*.ps1" \
  --exclude="REVIEW.md" \
  --exclude="输出代码资产的提示词.md" \
  2>/dev/null || true)

if [ -n "$LEAKED" ]; then
  echo "FAIL: 发现 /Users/minjianq 真实路径："
  echo "$LEAKED"
  exit 1
fi
echo "  ✓ 无 /Users/minjianq 泄露"

# 2. 扫描 /Users/qian 或其他真实用户名（兼容中文环境）
# 排除审计报告
echo "[T2] 扫描其他可能真实路径"
LEAKED2=$(grep -rnE "/Users/[a-z]+/(Documents|Downloads|Desktop|projects)/" "$REPO_ROOT" \
  --exclude-dir=".git" --exclude-dir="tests" --exclude-dir="node_modules" \
  --exclude="REVIEW.md" \
  --exclude="输出代码资产的提示词.md" \
  --include="*.md" --include="*.sh" --include="*.ps1" \
  2>/dev/null | grep -vE "/Users/[a-z]+/\$|<保密>|<保密路径>|placeholder|example" || true)

if [ -n "$LEAKED2" ]; then
  echo "WARN: 发现可能真实路径（请人工确认）："
  echo "$LEAKED2"
  # WARN 不退出，CI 决定
fi
echo "  ✓ 无明显真实路径"

# 3. 校验 wxcbrc-case.md 使用 <保密路径> 占位符
echo "[T3] 校验 wxcbrc-case.md 使用 <保密路径> 占位"
EXAMPLE="$REPO_ROOT/docs/examples/wxcbrc-case.md"
[ -f "$EXAMPLE" ] || { echo "FAIL: wxcbrc-case.md 不存在"; exit 1; }
grep -q "<保密路径>" "$EXAMPLE" || { echo "FAIL: wxcbrc-case.md 未用 <保密路径> 占位符"; exit 1; }
# 同时确认不含真实路径
if grep -q "/Users/" "$EXAMPLE"; then
  echo "FAIL: wxcbrc-case.md 含 /Users/ 真实路径"
  exit 1
fi
echo "  ✓ wxcbrc-case.md 已脱敏"

# 4. 扫描 C:\Users\... Windows 真实路径
# 排除审计报告
echo "[T4] 扫描 Windows 真实路径泄露"
LEAKED3=$(grep -rnE "C:\\\\Users\\\\[a-zA-Z]+" "$REPO_ROOT" \
  --exclude-dir=".git" --exclude-dir="tests" --exclude-dir="node_modules" \
  --exclude="REVIEW.md" \
  --exclude="输出代码资产的提示词.md" \
  --include="*.md" --include="*.sh" --include="*.ps1" \
  2>/dev/null || true)
if [ -n "$LEAKED3" ]; then
  echo "FAIL: 发现 Windows 真实路径："
  echo "$LEAKED3"
  exit 1
fi
echo "  ✓ 无 Windows 真实路径"

echo ""
echo "==> no-leak-path.test.sh: 全部 4 项通过"
