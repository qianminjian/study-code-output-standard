#!/usr/bin/env bash
# check-meta.sh — 校验每篇资产元信息头 7 字段
# 用法：bash scripts/check-meta.sh
set -e

REQUIRED=("id" "version" "last_updated" "data_source" "code_version" "owner" "ai_consumable")
DOCS_DIR="${DOCS_DIR:-asset-docs}"

if [ ! -d "$DOCS_DIR" ]; then
  echo "ERROR: $DOCS_DIR 目录不存在"
  exit 1
fi

errors=0
for f in "$DOCS_DIR"/*.md; do
  # 跳过非资产文件（README、CHANGELOG 等）
  basename="$(basename "$f")"
  case "$basename" in
    README.md|CHANGELOG.md|INDEX.md)
      continue
      ;;
  esac
  # 只校验 00-12 编号的资产
  if ! echo "$basename" | grep -qE "^[0-9]{2}-"; then
    continue
  fi
  for k in "${REQUIRED[@]}"; do
    if ! grep -q "\"$k\":" "$f"; then
      echo "MISSING META: $f 缺少字段 $k"
      errors=$((errors+1))
    fi
  done
done

if [ "$errors" -gt 0 ]; then
  echo "==> $errors 个错误"
  exit 1
fi

echo "==> OK: 所有资产元信息头完整"
