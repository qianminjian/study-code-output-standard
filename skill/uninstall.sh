#!/usr/bin/env bash
# uninstall.sh — 卸载 skill（幂等）
# 用法：bash uninstall.sh [target-dir]
#   target-dir 默认 ~/.claude/skills/study-code-output-standard

set -e

TARGET="${1:-$HOME/.claude/skills/study-code-output-standard}"
# Windows fallback
if [ -z "$HOME" ] && [ -n "$USERPROFILE" ]; then
  TARGET="${1:-$USERPROFILE/.claude/skills/study-code-output-standard}"
fi

# 支持多个常见路径
CANDIDATES=(
  "$TARGET"
  "$HOME/.claude/skills/study-code-output-standard"
  "${USERPROFILE:-$HOME}/.claude/skills/study-code-output-standard"
  "$(pwd)/.claude/skills/study-code-output-standard"
)

found=0
for c in "${CANDIDATES[@]}"; do
  if [ -e "$c" ]; then
    found=1
    if [ -L "$c" ]; then
      rm "$c"
      echo "✓ 已删除软链: $c"
    else
      rm -rf "$c"
      echo "✓ 已删除目录: $c"
    fi
  fi
done

if [ "$found" -eq 0 ]; then
  echo "未找到安装，跳过"
fi
