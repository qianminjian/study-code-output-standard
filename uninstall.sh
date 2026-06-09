#!/usr/bin/env bash
# uninstall.sh — 卸载 skill（幂等）
# 用法：bash uninstall.sh [target-dir]
#        bash uninstall.sh --path <dir>
#        bash uninstall.sh          # 自动找常见路径
#   target-dir 默认 ~/.claude/skills/study-code-output-standard
# 跨平台：Mac / Linux / Git Bash on Windows

set -e

VERSION="2.1.0"

# 修复 P3-02：支持 --path 参数
TARGET=""
case "${1:-}" in
  --path)
    TARGET="${2:-}"
    if [ -z "$TARGET" ]; then
      echo "ERROR: --path 需要指定目录" >&2
      exit 2
    fi
    ;;
  --version)
    echo "study-code-output-standard $VERSION"
    exit 0
    ;;
  --help|-h)
    cat <<EOF
用法：bash uninstall.sh [选项] [target-dir]

选项：
  --path <dir>   指定要卸载的目录
  --version      显示版本
  --help         显示帮助

默认行为：扫描常见路径（~/.claude/skills/、项目级 .claude/skills/）。
EOF
    exit 0
    ;;
  "")
    TARGET=""
    ;;
  *)
    # 兼容旧版：直接传 target-dir
    TARGET="$1"
    ;;
esac

# 修复 P2-08：Windows 路径统一用 cygpath 转 Unix 风格
HOME_NIX="$HOME"
USERPROFILE_NIX="$USERPROFILE"
if command -v cygpath >/dev/null 2>&1; then
  if [ -n "$USERPROFILE" ]; then
    USERPROFILE_NIX=$(cygpath -u "$USERPROFILE" 2>/dev/null || echo "$USERPROFILE")
  fi
  if [ -n "$HOME" ]; then
    HOME_NIX=$(cygpath -u "$HOME" 2>/dev/null || echo "$HOME")
  fi
fi

# 默认 target
if [ -z "$TARGET" ]; then
  TARGET="${USERPROFILE_NIX:-$HOME_NIX}/.claude/skills/study-code-output-standard"
fi

# 支持多个常见路径扫描
CANDIDATES=(
  "$TARGET"
  "$HOME_NIX/.claude/skills/study-code-output-standard"
  "${USERPROFILE_NIX:-$HOME_NIX}/.claude/skills/study-code-output-standard"
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
