#!/usr/bin/env bash
# check-severity.sh — 校验严重度字段
# 用法：bash scripts/check-severity.sh
set -e

DOCS_DIR="${DOCS_DIR:-docs}"

# 1. 检查自定义严重度
# 只匹配在表格列或 emoji 前缀的严重度（真使用），不匹配反引号包裹的"教学引用"
INVALID=$(grep -rE "^\| (P[4-9]|严重|高危|中危|低危) \||[🔴🟡🟢⚪] P[4-9]|\| (严重|高危|中危|低危) \|" "$DOCS_DIR" 2>/dev/null || true)
if [ -n "$INVALID" ]; then
  echo "INVALID SEVERITY FOUND:"
  echo "$INVALID" | head -10
  exit 1
fi

# 2. 统计分布
echo "=== 严重度分布 ==="
for level in P0 P1 P2 P3; do
  count=$(grep -rhE "[🔴🟡🟢⚪] $level|\\| $level \\|" "$DOCS_DIR" 2>/dev/null | wc -l | tr -d ' ')
  echo "  $level: $count"
done

# 3. 检查 P0 数量（应 < 10）
P0=$(grep -rhE "[🔴🟡🟢⚪] P0|\\| P0 \\|" "$DOCS_DIR" 2>/dev/null | wc -l | tr -d ' ')
if [ "$P0" -gt 10 ]; then
  echo "WARNING: P0 数量为 $P0，超过 10 = 可能没分级"
fi

echo "==> OK"
