#!/usr/bin/env bash
# validate-all.sh — shim，改名为 check-all.sh
# 用法：bash scripts/validate-all.sh  (向后兼容，自动转调 check-all.sh)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
echo "[DEPRECATED] validate-all.sh 已改名为 check-all.sh，本 shim 仅做向后兼容。"
echo "[DEPRECATED] 后续请用: bash scripts/check-all.sh"
exec "$SCRIPT_DIR/check-all.sh" "$@"
