#!/usr/bin/env bash
# check-meta.sh — 校验每篇资产元信息头 7 字段 + last_updated 时效
# 用法：bash scripts/check-meta.sh
#  code_version 改为可选（非 git 项目可留空 / 写 <unversioned>）
#         新增 last_updated > 30 天告警
set -e

REQUIRED=("id" "version" "last_updated" "data_source" "owner" "ai_consumable")
OPTIONAL=("code_version" "severity_taxonomy")
DOCS_DIR="${DOCS_DIR:-asset-docs}"
# v2.5 调整：STALE_DAYS 30 → 90
#   原因：archive_for_skill 实测（大项目 33 模块）跑完整 7 步法需 10+ min
#   旧 30 天阈值对大项目太严——大项目不可能 30 天内跑一次
#   大项目按 90 天，小项目可用 STALE_DAYS=30 覆盖
STALE_DAYS="${STALE_DAYS:-90}"

if [ ! -d "$DOCS_DIR" ]; then
  echo "ERROR: $DOCS_DIR 目录不存在"
  exit 1
fi

errors=0
stale_warnings=0
for f in "$DOCS_DIR"/*.md; do
  # 跳过非资产文件（README、CHANGELOG 等）
  basename="$(basename "$f")"
  case "$basename" in
    README.md|CHANGELOG.md|INDEX.md)
      continue
      ;;
  esac
  # 只校验 00-12 编号的资产（v2.3 #10：支持 100+ 编号）
  if ! echo "$basename" | grep -qE "^[0-9]{2,3}-"; then
    continue
  fi
  for k in "${REQUIRED[@]}"; do
    if ! grep -q "\"$k\":" "$f"; then
      echo "MISSING META: $f 缺少字段 $k"
      errors=$((errors+1))
    fi
  done

  # 校验 last_updated 距今不超过 STALE_DAYS 天（软告警，不阻断）
  last_updated="$(grep -E '"last_updated":' "$f" | head -1 | sed -E 's/.*"last_updated":[[:space:]]*"([^"]+)".*/\1/')"
  if [ -n "$last_updated" ] && [ "$last_updated" != "<YYYY-MM-DD>" ]; then
    # 用 Python 计算天数差（macOS 友好，无需 GNU date）
    days_old="$(python3 -c "from datetime import date; y,m,d=[int(x) for x in '$last_updated'.split('-')]; print((date.today() - date(y,m,d)).days)" 2>/dev/null || echo "")"
    if [ -n "$days_old" ] && [ "$days_old" -gt "$STALE_DAYS" ] 2>/dev/null; then
      echo "STALE: $f last_updated=$last_updated 距今 $days_old 天（阈值 $STALE_DAYS 天）"
      stale_warnings=$((stale_warnings+1))
    fi
  fi
done

if [ "$errors" -gt 0 ]; then
  echo "==> $errors 个错误"
  exit 1
fi

if [ "$stale_warnings" -gt 0 ]; then
  echo "==> OK（所有元信息头完整）；⚠ $stale_warnings 篇资产已过期，需 review"
else
  echo "==> OK: 所有资产元信息头完整且新鲜"
fi
