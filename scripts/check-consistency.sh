#!/usr/bin/env bash
# check-consistency.sh — 资产-代码一致性校验
# 用法：bash scripts/check-consistency.sh
#
# 注：本脚本示例基于 Java + Vue 项目。其它项目需调整路径。
set -e

SRC_DIR="${SRC_DIR:-src/main/java/com/example}"
DOCS_DIR="${DOCS_DIR:-asset-docs}"

if [ ! -d "$SRC_DIR" ]; then
  echo "WARN: $SRC_DIR 不存在，跳过一致性检查"
  echo "  设置 SRC_DIR 环境变量指向你的代码目录"
  exit 0
fi

# 1. 端点数
expected=$(grep -rE "@(Get|Post|Put|Delete)Mapping" "$SRC_DIR" 2>/dev/null | wc -l | tr -d ' ')
documented=$(grep -cE "^\| (GET|POST|PUT|DELETE) \|" "$DOCS_DIR"/03-*.md 2>/dev/null | head -1 || echo 0)
if [ -n "$expected" ] && [ -n "$documented" ]; then
  if [ "$expected" -ne "$documented" ]; then
    echo "MISMATCH: 端点数 expected=$expected documented=$documented"
    echo "  03-Controller 文档需补充 $((expected - documented)) 个端点"
    exit 1
  fi
  echo "OK: 端点数 $expected == 文档 $documented"
fi

# 2. Controller 数
expected=$(find "$SRC_DIR" -name "*Controller.java" 2>/dev/null | wc -l | tr -d ' ')
documented=$(awk '/^### 2\./{c++} END{print c}' "$DOCS_DIR"/03-*.md 2>/dev/null || echo 0)
if [ -n "$expected" ] && [ -n "$documented" ]; then
  if [ "$expected" -ne "$documented" ]; then
    echo "MISMATCH: Controller 数 expected=$expected documented=$documented"
    exit 1
  fi
  echo "OK: Controller 数 $expected == 文档 $documented"
fi

# 3. Mapper 数
expected=$(find "$SRC_DIR" -name "*Mapper.java" 2>/dev/null | wc -l | tr -d ' ')
documented=$(awk '/^### 3\./{c++} END{print c}' "$DOCS_DIR"/04-*.md 2>/dev/null || echo 0)
echo "INFO: Mapper 数 expected=$expected documented=$documented"

echo "==> OK"
