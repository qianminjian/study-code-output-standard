#!/usr/bin/env bash
# check-consistency.sh — 资产-代码一致性校验
# 用法：bash scripts/check-consistency.sh
#
# v2.3 TEST-ISSUES #13：
#   默认 SRC_DIR 改 src/main/java（用户级项目标准布局）
#   检测 placeholder 路径（com/example）→ ERROR 退出而非静默跳过
# v2.3 TEST-ISSUES #8：
#   03 模板加 §1-B 摘要表后，校验逻辑改为"摘要端点数 vs grep 数"对齐
set -e

DEFAULT_SRC_DIR="src/main/java"
SRC_DIR="${SRC_DIR:-$DEFAULT_SRC_DIR}"
DOCS_DIR="${DOCS_DIR:-asset-docs}"

# v2.3 #13：检测 placeholder 路径
case "$SRC_DIR" in
  *com/example*|*src/main/java/com/example*)
    echo "ERROR: SRC_DIR 仍是 placeholder ($SRC_DIR)"
    echo "  v2.3 起默认是 src/main/java；请用 SRC_DIR 环境变量传真实路径"
    echo "  例: SRC_DIR=wxcbrc_mgmt/wxcbrc_server/wxcbrc-boot/src/main/java/com/wrcb/wxcbrc/boot bash check-consistency.sh"
    exit 2
    ;;
esac

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: $SRC_DIR 不存在"
  echo "  设置 SRC_DIR 环境变量指向你的代码目录"
  exit 2
fi

# 1. 端点数
expected=$(grep -rE "@(Get|Post|Put|Delete)Mapping" "$SRC_DIR" 2>/dev/null | wc -l | tr -d ' ')
# v2.3 #8：从 03 模板 §1-B 摘要表读"端点总数"行
documented=$(grep -A 10 "## 1-B" "$DOCS_DIR"/03-*.md 2>/dev/null | grep -E "端点总数.*\|" | head -1 | grep -oE '[0-9]+' | head -1 || echo 0)
[ -n "$documented" ] || documented=0
if [ "$expected" -gt 0 ] && [ "$documented" -gt 0 ]; then
  if [ "$expected" -ne "$documented" ]; then
    echo "MISMATCH: 端点数 expected=$expected documented=$documented"
    echo "  03-Controller 文档 §1-B 摘要表需对齐 ($((expected - documented)) 差距)"
    exit 1
  fi
  echo "OK: 端点数 $expected == 摘要表 $documented"
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
