#!/usr/bin/env bash
# check-severity.sh — 校验严重度字段
# 用法：bash scripts/check-severity.sh
# 默认排除 templates/ 和 ai-prompts/ 子目录（这两个目录是教学副本）
# 可通过 SEVERITY_INCLUDE_DIRS 环境变量覆盖
set -e

DOCS_DIR="${DOCS_DIR:-asset-docs}"

# 修复 P2-03：默认排除 templates/ 和 ai-prompts/（教学副本会污染统计）
INCLUDE_ARGS=()
if [ -n "$SEVERITY_INCLUDE_DIRS" ]; then
  for d in $SEVERITY_INCLUDE_DIRS; do
    INCLUDE_ARGS+=("--include-dir=$d")
  done
fi

# 1. 检查自定义严重度
# 只匹配在表格列或 emoji 前缀的严重度（真使用），不匹配反引号包裹的"教学引用"
INVALID=$(grep -rE --exclude-dir=templates --exclude-dir=ai-prompts \
  "^\| (P[4-9]|严重|高危|中危|低危) \||[🔴🟡🟢⚪] P[4-9]|\| (严重|高危|中危|低危) \|" \
  "$DOCS_DIR" 2>/dev/null || true)
if [ -n "$INVALID" ]; then
  echo "INVALID SEVERITY FOUND:"
  echo "$INVALID" | head -10
  exit 1
fi

# 2. 统计分布
echo "=== 严重度分布 ==="
for level in P0 P1 P2 P3; do
  count=$(grep -rhE --exclude-dir=templates --exclude-dir=ai-prompts \
    "[🔴🟡🟢⚪] $level|\\| $level \\|" "$DOCS_DIR" 2>/dev/null | wc -l | tr -d ' ')
  echo "  $level: $count"
done

# 3. 检查 P0 数量（应 < 10）
# 修复 P0：Bash 3.2 + UTF-8 locale 下 echo "$P0, 超过 10" 会把 $P0 后面的内容吞掉
# 用 printf 替代 echo，并加 ${} 明确变量边界
P0=$(grep -rhE --exclude-dir=templates --exclude-dir=ai-prompts \
  "[🔴🟡🟢⚪] P0|\\| P0 \\|" "$DOCS_DIR" 2>/dev/null | wc -l | tr -d ' ' | head -1)
# 整数校验
case "$P0" in
  ''|*[!0-9]*) P0=0 ;;
esac
# v2.4 本轮 #9：统计总问题数 + P0 占比告警
TOTAL=$(grep -rhE --exclude-dir=templates --exclude-dir=ai-prompts \
  "[🔴🟡🟢⚪] P[0-3]|\\| P[0-3] \\|" "$DOCS_DIR" 2>/dev/null | wc -l | tr -d ' ' | head -1)
case "$TOTAL" in
  ''|*[!0-9]*) TOTAL=0 ;;
esac
if [ "${P0}" -gt 10 ]; then
  printf 'WARNING: P0 数量为 %s, 超过 10 = 可能没分级\n' "${P0}"
  if [ "${TOTAL}" -gt 0 ]; then
    P0_PCT=$((P0 * 100 / TOTAL))
    if [ "${P0_PCT}" -gt 10 ]; then
      printf '⚠️ 暂停建议：P0 占总问题 %d%% (P0=%d / TOTAL=%d)，远超 10%% 阈值\n' "${P0_PCT}" "${P0}" "${TOTAL}"
      printf '   建议：每 sprint 修 2-3 个 P0，避免一次塞大量 P0 进 sprint（质量保证原则）\n'
      printf '   优先修：secret-leak / sqlinjection / actuator-exposure（高 ROI）\n'
    fi
  fi
fi

echo "==> OK"
