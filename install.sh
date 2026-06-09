#!/usr/bin/env bash
# install.sh — 安装 study-code-output-standard skill
# 跨平台：Mac / Linux / Git Bash on Windows
#
# 用法：
#   bash install.sh --personal                安装到 ~/.claude/skills/（个人）
#   bash install.sh --project                 安装到当前项目的 .claude/skills/（项目级）
#   bash install.sh --path <dir>              安装到指定目录
#   bash install.sh --uninstall               卸载
#   bash install.sh --help                    帮助
#
# 选项：
#   --force / -f                              覆盖已存在的安装（非交互）

set -e

VERSION="2.3.0"

# 0. 解析参数
MODE=""
TARGET_DIR=""
UNINSTALL=false
DRY_RUN=false

# 用 while 循环以便处理带值的参数
ARGS=("$@")
i=0
while [ $i -lt ${#ARGS[@]} ]; do
  arg="${ARGS[$i]}"
  case "$arg" in
    --personal) MODE="personal"; i=$((i+1)) ;;
    --project) MODE="project"; i=$((i+1)) ;;
    --path)
      i=$((i+1))
      # 修复 P1-01：--path 后无值时报错退出（而非静默回退交互模式）
      if [ $i -ge ${#ARGS[@]} ]; then
        echo "ERROR: --path 需要指定目标目录" >&2
        echo "  用法: bash install.sh --path <dir>" >&2
        exit 2
      fi
      TARGET_DIR="${ARGS[$i]}"
      if [ -z "$TARGET_DIR" ]; then
        echo "ERROR: --path 的目标目录不能为空" >&2
        exit 2
      fi
      i=$((i+1))
      ;;
    --uninstall) UNINSTALL=true; i=$((i+1)) ;;
    --force|-f) FORCE=true; i=$((i+1)) ;;
    --dry-run) DRY_RUN=true; i=$((i+1)) ;;
    --version)
      echo "study-code-output-standard $VERSION"
      exit 0
      ;;
    --help|-h)
      cat <<EOF
用法：bash install.sh [选项]

选项：
  --personal     安装到 ~/.claude/skills/study-code-output-standard/（个人）
  --project      安装到当前项目的 .claude/skills/study-code-output-standard/
  --path <dir>   安装到指定目录
  --uninstall    卸载（删除安装）
  --help         显示帮助

默认行为：未指定模式时，提示选择。

跨平台：Mac / Linux / Git Bash on Windows（Windows 推荐用 Git Bash）
EOF
      exit 0
      ;;
    *)
      echo "未知选项: $arg"
      exit 1
      ;;
  esac
done

# 1. 定位 skill 根目录（重构 v2.1：仓库根 = skill 根 = SKILL.md 所在目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
  echo "ERROR: 无法定位 skill 目录"
  exit 1
fi
METHODOLOGY_DIR="$SCRIPT_DIR"

if [ ! -f "$SCRIPT_DIR/SKILL.md" ]; then
  echo "ERROR: 找不到 SKILL.md，方法论根目录不正确: $SCRIPT_DIR"
  echo "  期望: $SCRIPT_DIR/SKILL.md"
  exit 1
fi

# 2. 卸载模式
if [ "$UNINSTALL" = "true" ]; then
  bash "$SCRIPT_DIR/uninstall.sh" "${TARGET_DIR:-$HOME/.claude/skills/study-code-output-standard}"
  exit 0
fi

# 3. 选择安装目标
if [ -z "$MODE" ] && [ -z "$TARGET_DIR" ]; then
  echo "请选择安装模式："
  echo "  1) --personal  安装到 ~/.claude/skills/（个人，推荐）"
  echo "  2) --project   安装到当前项目的 .claude/skills/（团队）"
  echo "  3) --path DIR  安装到指定目录"
  read -p "  选择 [1/2/3]: " choice
  case "$choice" in
    1) MODE="personal" ;;
    2) MODE="project" ;;
    3) read -p "  目标目录: " TARGET_DIR ;;
    *) echo "已取消"; exit 1 ;;
  esac
fi

# 4. 计算目标目录
case "$MODE" in
  personal)
    # 修复 P1-02：HOME/USERPROFILE 双空时显式报错，避免安装到 / 下
    if [ -z "$HOME" ] && [ -z "$USERPROFILE" ]; then
      echo "ERROR: personal 模式需要 HOME 或 USERPROFILE 环境变量" >&2
      echo "  HOME=$HOME" >&2
      echo "  USERPROFILE=$USERPROFILE" >&2
      echo "  请用 --project 或 --path 显式指定" >&2
      exit 2
    fi
    TARGET_DIR="${HOME:-$USERPROFILE}/.claude/skills/study-code-output-standard"
    ;;
  project)
    TARGET_DIR="$(pwd)/.claude/skills/study-code-output-standard"
    ;;
esac

if [ -z "$TARGET_DIR" ]; then
  echo "ERROR: 未指定目标目录"
  exit 1
fi

# 5. 检查是否已存在
# FORCE 由主 case 解析（line 32）

if [ -e "$TARGET_DIR" ]; then
  echo "WARN: $TARGET_DIR 已存在"
  if [ -L "$TARGET_DIR" ]; then
    echo "  当前是软链，删除并重新创建"
    rm "$TARGET_DIR"
  elif [ "$FORCE" = "true" ]; then
    echo "  --force 模式：覆盖"
    rm -rf "$TARGET_DIR"
  else
    if [ -t 0 ]; then
      read -p "  覆盖？[y/N] " yn
      case "$yn" in
        [yY]*) rm -rf "$TARGET_DIR" ;;
        *) echo "已取消"; exit 1 ;;
      esac
    else
      # 修复 P1-03：非交互模式非 --force 时显式报错（不静默 exit 0）
      echo "  ERROR: 非交互模式且未指定 --force，拒绝覆盖" >&2
      echo "  解决: bash install.sh ... --force" >&2
      exit 2
    fi
  fi
fi

# 6. 创建父目录
mkdir -p "$(dirname "$TARGET_DIR")"

# 6.5 修复 P3-03：--dry-run 只打印不执行
if [ "$DRY_RUN" = "true" ]; then
  echo "[DRY-RUN] 将创建: $TARGET_DIR -> $METHODOLOGY_DIR"
  echo "[DRY-RUN] 父目录: $(dirname "$TARGET_DIR")"
  exit 0
fi

# 7. 创建软链（Mac/Linux）
if ln -s "$METHODOLOGY_DIR" "$TARGET_DIR" 2>/dev/null; then
  echo "✓ 已创建软链: $TARGET_DIR -> $METHODOLOGY_DIR"
else
  # 软链失败（Windows 非 Git Bash / 权限问题）：用 copy
  echo "WARN: 软链创建失败，改用 copy"
  cp -R "$METHODOLOGY_DIR" "$TARGET_DIR"
  echo "✓ 已 copy: $TARGET_DIR"
fi

echo ""
echo "==> 安装完成！"
echo ""
echo "下一步："
echo "  1. 重新打开 Claude Code"
echo "  2. 在任意项目根目录运行：claude"
echo "  3. 调用：/study-code-output-standard"
echo ""
echo "卸载：bash install.sh --uninstall"
