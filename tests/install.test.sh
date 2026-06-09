#!/usr/bin/env bash
# install.test.sh — 验证 install.sh / uninstall.sh 软链创建与删除
# 用法：bash tests/install.test.sh
set -e

# 1. 准备临时目录
TEST_DIR="$(mktemp -d -t study-install-XXXXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 2. install --path 应创建软链
echo "[T1] install --path 创建软链"
INSTALL_TARGET="$TEST_DIR/install-test"
bash "$REPO_ROOT/install.sh" --path "$INSTALL_TARGET" </dev/null >/dev/null 2>&1
[ -L "$INSTALL_TARGET" ] || { echo "FAIL: $INSTALL_TARGET 不是软链"; exit 1; }
TARGET_REAL="$(readlink "$INSTALL_TARGET")"
[ "$TARGET_REAL" = "$REPO_ROOT" ] || { echo "FAIL: 软链指向 $TARGET_REAL，应为 $REPO_ROOT"; exit 1; }
echo "  ✓ 软链: $INSTALL_TARGET -> $TARGET_REAL"

# 3. uninstall --path 应删除软链
echo "[T2] uninstall --path 删除软链"
bash "$REPO_ROOT/uninstall.sh" --path "$INSTALL_TARGET" >/dev/null 2>&1
[ ! -e "$INSTALL_TARGET" ] || { echo "FAIL: 软链未删除"; exit 1; }
echo "  ✓ 软链已删除"

# 4. install --path 无值应报错退出
echo "[T3] install --path 无值应报错退出"
set +e
bash "$REPO_ROOT/install.sh" --path </dev/null >/dev/null 2>&1
EXIT_CODE=$?
set -e
[ "$EXIT_CODE" = "2" ] || { echo "FAIL: 应退出 2，实际 $EXIT_CODE"; exit 1; }
echo "  ✓ 退出码 2"

# 5. install --help 应输出帮助
echo "[T4] install --help 输出帮助"
HELP_OUT="$(bash "$REPO_ROOT/install.sh" --help 2>&1)"
echo "$HELP_OUT" | grep -q "用法" || { echo "FAIL: --help 输出无 '用法'"; exit 1; }
echo "  ✓ 帮助输出正常"

# 6. install --version 应输出版本
echo "[T5] install --version 输出版本"
VERSION_OUT="$(bash "$REPO_ROOT/install.sh" --version 2>&1)"
echo "$VERSION_OUT" | grep -qE "study-code-output-standard [0-9]" || { echo "FAIL: --version 输出异常: $VERSION_OUT"; exit 1; }
echo "  ✓ 版本输出: $VERSION_OUT"

# 7. uninstall --path 无值应报错退出
echo "[T6] uninstall --path 无值应报错退出"
set +e
bash "$REPO_ROOT/uninstall.sh" --path </dev/null >/dev/null 2>&1
EXIT_CODE=$?
set -e
[ "$EXIT_CODE" = "2" ] || { echo "FAIL: 应退出 2，实际 $EXIT_CODE"; exit 1; }
echo "  ✓ 退出码 2"

# 8. install --dry-run 应只打印不执行
echo "[T7] install --dry-run 不创建软链"
DRY_TARGET="$TEST_DIR/dry-test"
bash "$REPO_ROOT/install.sh" --path "$DRY_TARGET" --dry-run </dev/null >/dev/null 2>&1
[ ! -e "$DRY_TARGET" ] || { echo "FAIL: --dry-run 不应创建 $DRY_TARGET"; exit 1; }
echo "  ✓ --dry-run 未实际创建"

echo ""
echo "==> install.test.sh: 全部 7 项通过"
