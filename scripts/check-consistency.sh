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
# v2.7 新增(Phase 1 可靠性加固):
#   1. 03 ↔ 05 endpoint-to-service mapping(端点路径 → Service 方法引用)
#   2. 02 ↔ 05 entity-to-business rule(⚠️ No DDL 表 → 05 业务逻辑说明)
#   3. 04 ↔ 06 SQL injection ↔ risk(04 注入点 → 06 §7 风险条目)
#   4. 03 ↔ 06 public endpoints ↔ security(公开端点数 → 无鉴权引用)
#   所有新检查为 INFO/WARN 级别(不阻塞)

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

# ===== v2.7 新增：4 项跨资产语义检查（Phase 1 可靠性加固）=====
# 所有新检查为 INFO/WARN 级别，不阻塞

# 7. 03 ↔ 05 endpoint-to-service mapping（03 每个端点是否在 05 中有对应 Service 方法）
if [ -f "$DOCS_DIR/03-后端-Controller接口清单.md" ] && [ -f "$DOCS_DIR/05-后端-服务与业务逻辑.md" ]; then
  # 从 03 §2 详细接口清单提取端点路径（如 /handle/xxx、/notice/xxx）
  endpoints_03=$(awk '/^## 2\./,/^## 3\./' "$DOCS_DIR/03-后端-Controller接口清单.md" 2>/dev/null \
    | grep -oE '`(/[a-zA-Z0-9_/\{\}-]+)`' \
    | sed -E 's/`//g' \
    | sort -u)
  ep_count=$(echo "$endpoints_03" | grep -c . 2>/dev/null || echo 0)
  if [ "$ep_count" -gt 0 ]; then
    matched=0
    unmatched_list=""
    for ep in $endpoints_03; do
      # 去掉路径参数（如 /{id}）和前缀，提取关键词用于在 05 中匹配
      keyword=$(echo "$ep" | sed -E 's|/[0-9]*$||' | sed -E 's|/\{[^}]+\}||g' | tr '/' '\n' | grep -v '^$' | tail -1)
      if [ -n "$keyword" ] && grep -qiE "\b$keyword\b" "$DOCS_DIR/05-后端-服务与业务逻辑.md" 2>/dev/null; then
        matched=$((matched + 1))
      else
        unmatched_list="$unmatched_list $ep"
      fi
    done
    coverage_pct=$(( matched * 100 / ep_count ))
    if [ "$coverage_pct" -lt 70 ]; then
      echo "WARN: 03→05 端点-Service 映射覆盖率 ${coverage_pct}% ($matched/$ep_count) — 建议补全"
      echo "  未在 05 中找到对应 Service 方法引用的端点（前 5 个）：$(echo "$unmatched_list" | tr ' ' '\n' | grep -v '^$' | head -5 | tr '\n' ' ')"
    else
      echo "INFO: 03→05 端点-Service 映射覆盖率 ${coverage_pct}% ($matched/$ep_count)"
    fi
  fi
fi

# 8. 02 ↔ 05 entity-to-business rule（02 标记的 ⚠️ No DDL 表是否在 05 中有说明）
if [ -f "$DOCS_DIR/02-数据模型与表结构.md" ] && [ -f "$DOCS_DIR/05-后端-服务与业务逻辑.md" ]; then
  # 提取 02 §1 中 ⚠️ 无 DDL / ⚠️ 无表 标记的实体名
  noddl_entities=$(awk -F'|' '/^## 1\./,/^## 2\./' "$DOCS_DIR/02-数据模型与表结构.md" 2>/dev/null \
    | grep -E '⚠️ 无表|⚠️ 无 DDL|⚠️.*无' \
    | grep -oE '\*\*[A-Z][a-zA-Z]+\*\*' \
    | sed -E 's/\*\*//g' \
    | sort -u)
  noddl_count=$(echo "$noddl_entities" | grep -c . 2>/dev/null || echo 0)
  if [ "$noddl_count" -gt 0 ]; then
    found=0
    missing_list=""
    for entity in $noddl_entities; do
      if grep -qiE "\b$entity\b" "$DOCS_DIR/05-后端-服务与业务逻辑.md" 2>/dev/null; then
        found=$((found + 1))
      else
        missing_list="$missing_list $entity"
      fi
    done
    if [ "$found" -lt "$noddl_count" ]; then
      echo "WARN: 02 ⚠️ 无 DDL 表 $found/$noddl_count 在 05 业务逻辑中有说明"
      echo "  未在 05 中说明的推断表：$(echo "$missing_list" | tr ' ' '\n' | grep -v '^$' | tr '\n' ' ')"
    else
      echo "OK: 02 ⚠️ 无 DDL 表 $found/$noddl_count 全部在 05 中有说明"
    fi
  else
    echo "INFO: 02 无 ⚠️ 推断表（全部有 DDL）"
  fi
fi

# 9. 04 ↔ 06 SQL injection ↔ risk（04 标记的 P0 注入点是否进入 06 §7）
if [ -f "$DOCS_DIR/04-后端-Mapper操作清单.md" ] && [ -f "$DOCS_DIR/06-后端-安全认证.md" ]; then
  # 从 04 提取标注了 SQL 注入风险的 Mapper 名或方法名
  # 模式 1：${} 动态 SQL（MyBatis 注入标记）
  injection_lines=$(grep -cE '\$\{.*\}' "$DOCS_DIR/04-后端-Mapper操作清单.md" 2>/dev/null || echo 0)
  # 模式 2：04 中标记的 P0 风险行
  p0_count_04=$(grep -cE 'P0|🔴 P0' "$DOCS_DIR/04-后端-Mapper操作清单.md" 2>/dev/null || echo 0)

  if [ "$injection_lines" -gt 0 ] || [ "$p0_count_04" -gt 0 ]; then
    # 检查 06 §7 是否包含 SQL 注入相关条目
    sec7_sqli=$(awk '/^## 7\./,/^## 元信息/' "$DOCS_DIR/06-后端-安全认证.md" 2>/dev/null \
      | grep -ciE 'SQL.*注入|注入.*SQL|动态.*SQL|\$\{' 2>/dev/null || echo 0)
    if [ "$sec7_sqli" -gt 0 ]; then
      echo "INFO: 04 SQL 注入标记 ${injection_lines} 处 / P0 ${p0_count_04} 个 → 06 §7 有 $sec7_sqli 条对应条目"
    else
      echo "WARN: 04 有 ${injection_lines} 处 \${} 动态 SQL / P0 ${p0_count_04} 个，但 06 §7 未收录 SQL 注入风险"
    fi
  else
    echo "INFO: 04 未检测到 SQL 注入标记（\${} 或 P0），跳过 04→06 注入交叉检查"
  fi
fi

# 10. 03 ↔ 06 public endpoints ↔ security（03 公开端点数是否与 06 无鉴权端点一致）
if [ -f "$DOCS_DIR/03-后端-Controller接口清单.md" ] && [ -f "$DOCS_DIR/06-后端-安全认证.md" ]; then
  # 方式 1：从 03 §1 摘要表提取"公开端点数"列（第 5 列，"鉴权策略"前）
  pub03_from_table=$(awk -F'|' '/^## 1\./,/^## 2\./' "$DOCS_DIR/03-后端-Controller接口清单.md" 2>/dev/null \
    | grep -E '^\| *`[A-Z]' \
    | awk -F'|' '{gsub(/ /,"",$6); sum+=$6} END{print sum+0}')

  # 方式 2：从 03 §4 公开端点表格数行数
  pub03_from_s4=$(awk '/^## 4\./,/^## 5\./' "$DOCS_DIR/03-后端-Controller接口清单.md" 2>/dev/null \
    | grep -cE '^\| `?[A-Z]' 2>/dev/null || echo 0)

  # 取较大值（§4 可能不完全，§1 是人工统计）
  if [ "$pub03_from_table" -gt "$pub03_from_s4" ]; then
    pub03=$pub03_from_table
  else
    pub03=$pub03_from_s4
  fi

  # 从 06 提取"无需认证"/"公开"等无鉴权端点引用
  unauth_06=$(grep -ciE '无需认证|无鉴权|permitAll|公开端点|匿名访问|allowAll' "$DOCS_DIR/06-后端-安全认证.md" 2>/dev/null || echo 0)

  if [ "$pub03" -gt 0 ] && [ "$unauth_06" -gt 0 ]; then
    echo "INFO: 03 公开端点 ≈ $pub03 个，06 无鉴权引用 $unauth_06 处 — 人工核查对齐"
  elif [ "$pub03" -gt 0 ] && [ "$unauth_06" -eq 0 ]; then
    echo "WARN: 03 有 $pub03 个公开端点，但 06 未提及无鉴权端点 — 安全资产可能不完整"
  elif [ "$pub03" -eq 0 ] && [ "$unauth_06" -gt 0 ]; then
    echo "WARN: 06 提到 $unauth_06 处无鉴权引用，但 03 公开端点数为 0 — 03 §1 摘要表可能漏填公开端点数"
  else
    echo "INFO: 03 公开端点数与 06 无鉴权引用均为 0 — 可能全部端点需鉴权"
  fi
fi

echo "==> OK"
