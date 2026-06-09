#!/usr/bin/env bash
# check-all.sh — 一键跑所有校验（v2.2 起替代 validate-all.sh）
# 用法：bash scripts/check-all.sh
# 向后兼容：bash scripts/validate-all.sh 仍可跑（shim 转调本脚本）
#
# v2.3 修复（修 TEST-ISSUES #5）：
# 不再 set -e 一票否决；改为收集子脚本退出码，最终根据 errors 计数输出
# "全部校验通过" 或 "校验完成：N 个步骤失败"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 子脚本执行包装器：执行后保留退出码（不因 set -e 退出）
# 用法：run_step "<step-name>" bash "$SCRIPT_DIR/check-xxx.sh"
errors=0
run_step() {
  local name="$1"
  shift
  echo "================================"
  echo " $name"
  echo "================================"
  if ! "$@"; then
    echo ""
    echo "⚠ STEP FAILED: $name (exit code $?)"
    errors=$((errors+1))
  fi
}

# 1. 元信息头校验
run_step "1/4 元信息头校验" \
  bash "$SCRIPT_DIR/check-meta.sh"

echo ""
# 2. 严重度校验
run_step "2/4 严重度校验" \
  bash "$SCRIPT_DIR/check-severity.sh"

echo ""
# 3. 一致性校验（DOCS_DIR/SRC_DIR 透传）
run_step "3/4 一致性校验" \
  env DOCS_DIR="${DOCS_DIR:-asset-docs}" SRC_DIR="${SRC_DIR:-src}" \
  bash "$SCRIPT_DIR/check-consistency.sh"

echo ""
# 4. 反模式扫描（SRC_DIR/XML_DIR 透传）
run_step "4/4 反模式扫描" \
  env SRC_DIR="${SRC_DIR:-src}" XML_DIR="${XML_DIR:-${SRC_DIR}/main/resources/mybatis}" \
  bash "$SCRIPT_DIR/scan-antipatterns.sh"

echo ""
echo "================================"
echo " 总结"
echo "================================"
if [ "$errors" -eq 0 ]; then
  echo "==> 全部校验通过"
  exit 0
else
  echo "==> 校验完成：$errors 个步骤失败（详见上方 ⚠ 标记）"
  exit 1
fi
