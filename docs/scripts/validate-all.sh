#!/usr/bin/env bash
# validate-all.sh — 一键跑所有校验
# 用法：bash scripts/validate-all.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================"
echo " 1/4 元信息头校验"
echo "================================"
DOCS_DIR="${DOCS_DIR:-asset-docs}" bash "$SCRIPT_DIR/check-meta.sh"

echo ""
echo "================================"
echo " 2/4 严重度校验"
echo "================================"
DOCS_DIR="${DOCS_DIR:-asset-docs}" bash "$SCRIPT_DIR/check-severity.sh"

echo ""
echo "================================"
echo " 3/4 一致性校验"
echo "================================"
DOCS_DIR="${DOCS_DIR:-asset-docs}" SRC_DIR="${SRC_DIR:-src}" bash "$SCRIPT_DIR/check-consistency.sh"

echo ""
echo "================================"
echo " 4/4 反模式扫描"
echo "================================"
SRC_DIR="${SRC_DIR:-src}" XML_DIR="${XML_DIR:-$SRC_DIR/main/resources/mybatis}" bash "$SCRIPT_DIR/scan-antipatterns.sh"

echo ""
echo "==> 全部校验通过"
