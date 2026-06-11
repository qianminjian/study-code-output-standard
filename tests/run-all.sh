#!/usr/bin/env bash
# run-all.sh — 跑全部 tests/ 套件，聚合结果
# 用法：bash tests/run-all.sh
#
# 任何子测试失败即整体失败（exit 1）
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TESTS=(
  init-validate.test.sh
  secrets.test.sh
  no-leak-path.test.sh
)

PASS=0
FAIL=0
FAILED_TESTS=()

for t in "${TESTS[@]}"; do
  echo ""
  echo "========================================"
  echo " 跑 $t"
  echo "========================================"
  if bash "$SCRIPT_DIR/$t"; then
    PASS=$((PASS+1))
  else
    FAIL=$((FAIL+1))
    FAILED_TESTS+=("$t")
  fi
done

echo ""
echo "========================================"
echo " 汇总"
echo "========================================"
echo "  通过: $PASS"
echo "  失败: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "  失败清单："
  for t in "${FAILED_TESTS[@]}"; do
    echo "    - $t"
  done
  exit 1
fi
echo "==> tests/run-all.sh: 全部 $PASS 个测试套件通过"
