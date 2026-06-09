#!/usr/bin/env bash
# check-debt-vs-scan.sh — 11-技术债 vs scan 实际命中的 diff 报告（v2.3 新增）
# 用法：bash scripts/check-debt-vs-scan.sh
#
# 目的：把 11-技术债.md 中"（推断）"标注的 P0/P1 与 scan 实际命中对账，
#       标出"人工标了但 scan 没扫到"的项目——这些是**必须人工 Read 全文确认**的候选。
#
# 输出：纯 WARN，不阻断。

DOCS_DIR="${DOCS_DIR:-asset-docs}"
DEBT_FILE="$DOCS_DIR/11-技术债与遗留项.md"

if [ ! -f "$DEBT_FILE" ]; then
  echo "WARN: $DEBT_FILE 不存在"
  echo "  请先 init asset-docs/ 并填充 11"
  exit 0
fi

# 1. 提取 11 中所有 @xxx 标签（含推断标注）
echo "==> 11-技术债中的反模式标签："
debt_tags=$(grep -oE '`@[a-z-]+`' "$DEBT_FILE" 2>/dev/null | sort -u)
if [ -z "$debt_tags" ]; then
  echo "  (未提取到标签)"
  exit 0
fi
echo "$debt_tags"

# 2. 提取每个标签的"位置"列（推断/真实）
echo ""
echo "==> 推断 vs 真实分类："
echo "  推断标注的位置："
grep -cE '（推断）|（需 Read 全文）' "$DEBT_FILE" 2>/dev/null || echo "  0"
echo "  真实位置（无推断标注）："
grep -cvE '（推断）|（需 Read 全文）' "$DEBT_FILE" 2>/dev/null || echo "  0"

# 2.5 v2.4 本轮 #8：暂停阈值检查（P0 待验 ≥ 3 → 强烈建议暂停）
p0_pending=$(grep -E '🔴 P0' "$DEBT_FILE" 2>/dev/null | grep -cE '（推断）|（需 Read 全文）' || echo 0)
if [ "$p0_pending" -ge 3 ]; then
  echo ""
  echo "⚠️ 暂停建议：$p0_pending 个 P0 待人工 Read 全文确认（阈值 ≥ 3）"
  echo "   强烈建议：先 Read 全文确认 P0 真实性，再写 12-修复建议"
  echo "   否则 12 中的修复方案可能基于错误假设，浪费工作量"
fi

# 3. 提示用户做 diff
echo ""
echo "==> Diff 报告（建议人工跑 scan 后对照）："
echo "  跑 scan：bash \${SKILL_HOME}/scripts/scan-antipatterns.sh > /tmp/scan.txt 2>&1"
echo "  对照：grep -E '`@[a-z-]+`' 11-技术债.md vs grep 标签节  /tmp/scan.txt"
echo ""
echo "  ⚠ 特别注意：标签被人工标了但 scan 漏检的——必须 Read 全文确认 P0/P1 真实性"
echo "  ⚠ scan 命中但 11 未标的——可能是漏标，建议 review"

# 4. 静态检测：scan 漏检 + 人工标 P0 的——高风险
echo ""
echo "==> 高风险检查（人工标了 P0 但 scan 未覆盖的）："
high_risk=0
for tag in $(echo "$debt_tags" | tr -d '`' | sed 's/@//'); do
  # 检查 scan 脚本里有没有这标签的扫描命令
  if ! grep -q "@$tag" "${SKILL_HOME:-$(dirname "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")")}/scripts/scan-antipatterns.sh" 2>/dev/null; then
    if ! grep -q "@$tag\|`$tag`" "$DEBT_FILE" 2>/dev/null; then
      : # 跳过——没在 scan 也没在 11
    else
      severity=$(grep -A 2 "@$tag" "$DEBT_FILE" 2>/dev/null | grep -oE '🔴 P0|🟡 P1|🟢 P2' | head -1)
      if [ "$severity" = "🔴 P0" ]; then
        echo "  ⚠ @$tag — 标了 P0 但 scan 脚本未覆盖（高风险，需 Read 全文确认）"
        high_risk=$((high_risk+1))
      fi
    fi
  fi
done

if [ "$high_risk" -gt 0 ]; then
  echo ""
  echo "==> $high_risk 个 P0 标签需人工 Read 全文确认（scan 漏检）"
else
  echo "==> OK：所有 P0 标签 scan 都有覆盖"
fi
