#!/usr/bin/env bash
# check-consistency.sh — 资产-代码一致性校验
# 用法:bash scripts/check-consistency.sh
#
# v2.5 改进(Gap 6 modified 修复):
#   1. 端点 grep 仅匹配 Controller 类(排除 test/ 和非 Controller 文件)
#   2. Controller grep 排除 test/ 目录
#   3. 新增 4 项跨资产语义检查(02/03/04/06 一致性)
#   4. 移除 set -e(新检查多 optional,避免 grep 空匹配误退)
# v2.6 修复:03 摘要表用反引号而非尖括号,正则适配

DEFAULT_SRC_DIR="src/main/java"
SRC_DIR="${SRC_DIR:-$DEFAULT_SRC_DIR}"
DOCS_DIR="${DOCS_DIR:-asset-docs}"

# v2.3 #13:检测 placeholder 路径
case "$SRC_DIR" in
  *com/example*|*src/main/java/com/example*)
    echo "ERROR: SRC_DIR 仍是 placeholder ($SRC_DIR)"
    echo "  默认是 src/main/java;请用 SRC_DIR 环境变量传真实路径"
    echo "  例: SRC_DIR=wxcbrc_mgmt/wxcbrc_server/wxcbrc-boot/src/main/java/com/wrcb/wxcbrc/boot bash check-consistency.sh"
    exit 2
    ;;
esac

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: $SRC_DIR 不存在"
  echo "  设置 SRC_DIR 环境变量指向你的代码目录"
  exit 2
fi

# 辅助函数:列出所有 Controller 文件(排除 test/ 和 Test*.java)
list_controllers() {
  find "$SRC_DIR" -name "*Controller.java" \
    -not -path "*/test/*" \
    -not -path "*/Test*.java" 2>/dev/null
}

# 辅助函数:仅在 Controller 中 grep @Mapping(排除 test/ 和其他)
grep_endpoints() {
  list_controllers | xargs grep -E "@(Get|Post|Put|Delete)Mapping" 2>/dev/null
}

# 1. 端点数(仅 Controller 类,排除 test)
expected=$(grep_endpoints | wc -l | tr -d ' ')
# 从 §1 摘要表的"| `Controller` | <prefix> | ... | <N> |"行提取"端点数"列(第 4 列)
# v2.5:支持反引号(03 模板实际格式)
documented=$(awk -F'|' '/^## 1\./,/^## 2\./' "$DOCS_DIR"/03-*.md 2>/dev/null \
  | grep -E '^\| *`[A-Z]' \
  | awk -F'|' '{gsub(/ /,"",$5); sum+=$5} END{print sum+0}')
[ -n "$documented" ] || documented=0
if [ "$expected" -gt 0 ] && [ "$documented" -gt 0 ]; then
  if [ "$expected" -ne "$documented" ]; then
    echo "MISMATCH: 端点数 expected=$expected documented=$documented (v2.5 仅 Controller grep)"
    echo "  03-Controller 文档 §1 摘要表"端点数"列之和需对齐 ($((expected - documented)) 差距)"
    echo "  注意:已自动排除 test/ 和 Test*.java,如仍不等说明 03 资产漏记或多记"
    exit 1
  fi
  echo "OK: 端点数 $expected == 摘要表 §1 $documented (v2.5 仅 Controller grep)"
fi

# 2. Controller 数(排除 test/)
expected=$(list_controllers | wc -l)
# v2.5:支持反引号(03 模板实际格式)
documented=$(awk -F'|' '/^## 1\./,/^## 2\./' "$DOCS_DIR"/03-*.md 2>/dev/null \
  | grep -cE '^\| *`[A-Z][a-zA-Z]+`')
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

# ===== v2.5 新增:跨资产语义检查 (Gap 6 modified 修复) =====

# 4. 02 entity 名 vs 03 controller 引用一致性
# 02 §1 表格用 **EntityName** 加粗(无尖括号)
if [ -f "$DOCS_DIR/02-数据模型与表结构.md" ] && [ -f "$DOCS_DIR/03-后端-Controller接口清单.md" ]; then
  entities=$(awk -F'|' '/^## 1\./,/^## 2\./' "$DOCS_DIR/02-数据模型与表结构.md" 2>/dev/null \
    | grep -oE '\*\*[A-Z][a-zA-Z]+\*\*' \
    | sed -E 's/\*\*//g' \
    | sort -u)
  entity_count=$(echo "$entities" | grep -c . 2>/dev/null || echo 0)
  if [ "$entity_count" -gt 0 ]; then
    referenced=0
    for entity in $entities; do
      if grep -qE "\b$entity\b" "$DOCS_DIR/03-后端-Controller接口清单.md" 2>/dev/null; then
        referenced=$((referenced + 1))
      fi
    done
    echo "INFO: 02 entity $entity_count 个,$referenced 个在 03 中显式引用"
  fi
fi

# 5. 02 ⚠️ 推断表 vs 04 Mapper 引用(粗略:推断表名应在某 Mapper XML namespace 出现)
# 注:推断表本身在 §1 表格中(以 ⚠️ 标记),不是 §2-B
if [ -f "$DOCS_DIR/02-数据模型与表结构.md" ] && [ -f "$DOCS_DIR/04-后端-Mapper操作清单.md" ]; then
  inferred=$(awk -F'|' '/^## 1\./,/^## 2\./' "$DOCS_DIR/02-数据模型与表结构.md" 2>/dev/null \
    | grep -E '⚠️ 无表|⚠️ 无 DDL' \
    | sed -E 's/.*\*\*([A-Z][a-zA-Z]+)\*\*.*/\1/' \
    | sort -u)
  inferred_count=$(echo "$inferred" | grep -c . 2>/dev/null || echo 0)
  if [ "$inferred_count" -gt 0 ]; then
    found=0
    for tbl in $inferred; do
      if grep -qE "\b$tbl\b" "$DOCS_DIR/04-后端-Mapper操作清单.md" 2>/dev/null; then
        found=$((found + 1))
      fi
    done
    if [ "$found" -lt "$inferred_count" ]; then
      echo "WARN: 02 ⚠️ 推断表 $found/$inferred_count 在 04 Mapper 中显式出现"
    else
      echo "OK: 02 ⚠️ 推断表 $found/$inferred_count 全部在 04 Mapper 中"
    fi
  fi
fi

# 6. 06 P0/P1 风险位置 vs 11 技术债(粗略:06 的 file:line 引用必须在 11 中能找到)
if [ -f "$DOCS_DIR/06-后端-安全认证.md" ] && [ -f "$DOCS_DIR/11-技术债与遗留项.md" ]; then
  risk_files=$(awk '/^## 7\./,/^## 元信息/' "$DOCS_DIR/06-后端-安全认证.md" 2>/dev/null \
    | grep -oE '[A-Za-z][A-Za-z0-9_-]+\.(java|yml|properties)' \
    | sort -u)
  risk_count=$(echo "$risk_files" | grep -c . 2>/dev/null || echo 0)
  if [ "$risk_count" -gt 0 ]; then
    found=0
    for f in $risk_files; do
      if grep -qE "\b$f\b" "$DOCS_DIR/11-技术债与遗留项.md" 2>/dev/null; then
        found=$((found + 1))
      fi
    done
    coverage_pct=$(( found * 100 / risk_count ))
    if [ "$coverage_pct" -lt 50 ]; then
      echo "WARN: 06 风险位置 $found/$risk_count (${coverage_pct}%) 进入 11 资产 — 建议补全"
    else
      echo "OK: 06 风险位置 $found/$risk_count (${coverage_pct}%) 进入 11 资产"
    fi
  fi
fi

echo "==> OK"
