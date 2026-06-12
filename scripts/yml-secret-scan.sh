#!/usr/bin/env bash
# yml-secret-scan.sh — 扫描 yml/properties 中的密文明文（scan-antipatterns.sh v2.6 helper）
ROOT="${1:-}"
[ -n "$ROOT" ] || { echo "用法: $0 <PROJECT_ROOT_DIR>" >&2; exit 2; }
[ -d "$ROOT" ] || { echo "ERROR: $ROOT 不存在" >&2; exit 2; }
# 策略：扫 yml 中所有含 password/secret/apikey 且值非纯 ${VAR} 的行
# 简单 regex 避免脚本引号转义——先 grep 行再人工 review
grep -rnE '\b(password|secret|passwd|apikey|api_key|access_key|private_key)\s*:\s*.*[a-zA-Z0-9@.]{8,}' "$ROOT" --include='*.yml' --include='*.yaml' --include='*.properties' 2>/dev/null | grep -v '/test/' | head -15
