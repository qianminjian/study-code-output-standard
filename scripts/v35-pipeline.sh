#!/usr/bin/env bash
# v35-pipeline.sh — v3.5 一键跑管线（Step 0-2 自动化勘探+分类+规模检测）
# 用法：bash scripts/v35-pipeline.sh <module-path>
#
# 功能：
#   Step -1: 规模检测 + 模式路由（Java 文件数 → v3.0/v3.5 决策）
#   Step 0:  启动确认（项目类型/技术栈/目录结构）
#   Step 1:  勘探（Controller/Service/Mapper/Model 文件计数，技术栈提取）
#   Step 2:  分类（前端检测，资产覆盖决策，.phase-facts.md 生成）
#
# 输出：准备就绪提示 + Phase 1 Worker Spawn 完整命令
# 不包含实际的 Agent spawn（需要编排者调用）

set -e

# ---- 参数解析 ----

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "用法：bash scripts/v35-pipeline.sh <module-path>"
  echo ""
  echo "示例："
  echo "  bash scripts/v35-pipeline.sh /path/to/my-project"
  echo "  bash scripts/v35-pipeline.sh ~/work/devops-message"
  echo ""
  echo "输出："
  echo "  1. Step -1 规模检测报告"
  echo "  2. Step 0 启动确认"
  echo "  3. Step 1 勘探结果"
  echo "  4. Step 2 分类决策"
  echo "  5. Phase 1 Worker Spawn 就绪提示"
  exit 1
fi

TARGET="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"
if [ ! -d "$TARGET" ]; then
  echo "ERROR: 目标路径不存在: $TARGET"
  exit 1
fi

SKILL_HOME="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." 2>/dev/null && pwd || echo "")"
if [ ! -f "$SKILL_HOME/SKILL.md" ]; then
  # 退化：从 script 自身目录向上找
  CUR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
  for i in 1 2 3 4 5; do
    if [ -f "$CUR/SKILL.md" ]; then
      SKILL_HOME="$CUR"
      break
    fi
    CUR="$(dirname "$CUR")"
  done
fi

MODULE_NAME="$(basename "$TARGET")"
OUTPUT_DIR="$TARGET/asset-docs"
GEN_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo ""
echo "================================================"
echo " v3.5 Pipeline — 预处理管线"
echo "================================================"
echo " 模块：$MODULE_NAME"
echo " 路径：$TARGET"
echo " 时间：$GEN_TIME"
echo " Skill：$SKILL_HOME"
echo ""

# ============================================================
# Step -1: 规模检测与模式路由
# ============================================================

echo "----------------------------------------"
echo " Step -1: 规模检测与模式路由"
echo "----------------------------------------"

# 项目类型检测
PROJECT_TYPE="unknown"
BUILD_FILE=""
if [ -f "$TARGET/pom.xml" ]; then
  PROJECT_TYPE="java-maven"
  BUILD_FILE="pom.xml"
elif [ -f "$TARGET/build.gradle" ] || [ -f "$TARGET/build.gradle.kts" ]; then
  PROJECT_TYPE="java-gradle"
  BUILD_FILE="build.gradle"
elif [ -f "$TARGET/package.json" ]; then
  PROJECT_TYPE="nodejs"
  BUILD_FILE="package.json"
elif [ -f "$TARGET/go.mod" ]; then
  PROJECT_TYPE="go"
  BUILD_FILE="go.mod"
elif [ -f "$TARGET/requirements.txt" ] || [ -f "$TARGET/pyproject.toml" ]; then
  PROJECT_TYPE="python"
  BUILD_FILE="requirements.txt"
elif [ -f "$TARGET/Cargo.toml" ]; then
  PROJECT_TYPE="rust"
  BUILD_FILE="Cargo.toml"
fi

echo "  项目类型: $PROJECT_TYPE"
echo "  构建文件: $BUILD_FILE"

# Java 文件计数（仅 Java 项目）
JAVA_COUNT=0
JAVA_LOC=0
if [[ "$PROJECT_TYPE" == java-* ]]; then
  JAVA_COUNT=$(find "$TARGET" -name "*.java" -not -path "*/test/*" 2>/dev/null | wc -l | tr -d ' ')
  JAVA_LOC=$(find "$TARGET" -name "*.java" -not -path "*/test/*" 2>/dev/null | xargs cat 2>/dev/null | wc -l | tr -d ' ')
  echo "  Java 文件: $JAVA_COUNT"
  echo "  Java 行数: $JAVA_LOC"
else
  # 通用文件计数
  SRC_FILES=$(find "$TARGET" -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/target/*" -not -path "*/build/*" -not -path "*/dist/*" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "  源文件总数: $SRC_FILES"
fi

# 规模路由决策
MODE="v3.0"
SAMPLING="disabled"
SCALE_LEVEL="small"

if [[ "$PROJECT_TYPE" == java-* ]]; then
  if [ "$JAVA_COUNT" -le 200 ]; then
    MODE="v3.0"
    SCALE_LEVEL="small"
    REASON="Java ≤ 200 文件，单 agent 轻松覆盖"
  elif [ "$JAVA_COUNT" -le 500 ]; then
    MODE="v3.0"
    SCALE_LEVEL="medium"
    REASON="Java 201-500 文件，v3.0 可行（Read ≤ 500 行/文件）"
  elif [ "$JAVA_COUNT" -le 1000 ]; then
    MODE="v3.5"
    SAMPLING="required"
    SCALE_LEVEL="large"
    REASON="Java 501-1000 文件，v3.5 并行 + 分层抽样推荐"
  else
    MODE="v3.5"
    SAMPLING="required"
    SCALE_LEVEL="xlarge"
    REASON="Java > 1000 文件，v3.5 并行 + 分层抽样必须"
  fi
else
  # 非 Java 项目：保守使用 v3.0
  MODE="v3.0"
  SCALE_LEVEL="unknown"
  REASON="非 Java 项目，默认 v3.0（v3.5 仅 Java 验证过）"
fi

echo ""
echo "  >>> 规模路由决策"
echo "  模式: $MODE"
echo "  规模: $SCALE_LEVEL"
echo "  分层抽样: $SAMPLING"
echo "  原因: $REASON"
echo ""

# 分层抽样参数（仅 v3.5 + sampling 时生效）
if [ "$SAMPLING" = "required" ]; then
  TIER1_COUNT=$(find "$TARGET" -name "*.java" -not -path "*/test/*" | xargs grep -lE "@RestController|@Controller|@Configuration|@Component" 2>/dev/null | grep -v "test/" | wc -l | tr -d ' ')
  TIER2_COUNT=$(find "$TARGET" -name "*Service*.java" -o -name "*ServiceImpl*.java" 2>/dev/null | grep -v "test/" | wc -l | tr -d ' ')
  TIER3_COUNT=$(find "$TARGET" -name "*Mapper*.java" -o -name "*Entity*.java" -o -name "*Model*.java" -o -name "*.xml" 2>/dev/null | grep -v "test/" | wc -l | tr -d ' ')
  TIER4_COUNT=$(find "$TARGET" -name "*Handler*.java" -o -name "*Util*.java" -o -name "*VO*.java" -o -name "*DTO*.java" 2>/dev/null | grep -v "test/" | wc -l | tr -d ' ')

  echo "  分层抽样预估："
  echo "    Tier 1 (100%): $TIER1_COUNT 文件 (Controller/Config/Security)"
  echo "    Tier 2 (50%):  $TIER2_COUNT 文件 (Service)"
  echo "    Tier 3 (30%):  $TIER3_COUNT 文件 (Mapper/Entity/XML)"
  echo "    Tier 4 (20%):  $TIER4_COUNT 文件 (Handler/Util/VO/DTO)"
  echo ""
  ESTIMATED_TOTAL=$(( TIER1_COUNT + (TIER2_COUNT/2) + (TIER3_COUNT*3/10) + (TIER4_COUNT/5) ))
  echo "  预计读取文件: ~$ESTIMATED_TOTAL 个"
  echo ""
fi

# ============================================================
# Step 0: 启动确认
# ============================================================

echo "----------------------------------------"
echo " Step 0: 启动确认"
echo "----------------------------------------"

# 技术栈提取
echo "  提取技术栈..."

LANG=""
FRAMEWORK=""
DB_TYPE=""
ORM=""
BUILD_TOOL=""
SRC_DIR=""

case "$PROJECT_TYPE" in
  java-maven)
    LANG="Java"
    BUILD_TOOL="Maven"

    # Spring Boot 版本
    if [ -f "$TARGET/pom.xml" ]; then
      SPRING_VER=$(grep -oP '<spring-boot\.version>\K[^<]+' "$TARGET/pom.xml" 2>/dev/null || \
                   grep -oP 'spring-boot-starter-parent.*version.*>\K[^<]+' "$TARGET/pom.xml" 2>/dev/null || \
                   echo "")
      [ -n "$SPRING_VER" ] && FRAMEWORK="Spring Boot $SPRING_VER" || FRAMEWORK="Spring Boot"

      # ORM
      if grep -q "mybatis-plus" "$TARGET/pom.xml" 2>/dev/null; then
        ORM="MyBatis-Plus"
      elif grep -q "mybatis" "$TARGET/pom.xml" 2>/dev/null; then
        ORM="MyBatis"
      elif grep -q "spring-data-jpa\|hibernate" "$TARGET/pom.xml" 2>/dev/null; then
        ORM="JPA/Hibernate"
      else
        ORM="—"
      fi

      # DB
      if grep -q "mysql" "$TARGET/pom.xml" 2>/dev/null; then
        DB_TYPE="MySQL"
      elif grep -q "postgresql" "$TARGET/pom.xml" 2>/dev/null; then
        DB_TYPE="PostgreSQL"
      elif grep -q "oracle" "$TARGET/pom.xml" 2>/dev/null; then
        DB_TYPE="Oracle"
      else
        DB_TYPE="—"
      fi
    fi

    # 源码目录
    if [ -d "$TARGET/src/main/java" ]; then
      SRC_DIR="$TARGET/src/main/java"
    elif SRC_DIR=$(find "$TARGET" -maxdepth 3 -type d -name "java" -path "*/src/main/*" 2>/dev/null | head -1); then
      :  # SRC_DIR already set
    fi
    ;;
  java-gradle)
    LANG="Java"
    BUILD_TOOL="Gradle"
    FRAMEWORK="Spring Boot"
    SRC_DIR=$(find "$TARGET" -maxdepth 3 -type d -name "java" -path "*/src/main/*" 2>/dev/null | head -1 || echo "")
    ;;
  nodejs)
    LANG="TypeScript/JavaScript"
    BUILD_TOOL="npm"
    if [ -f "$TARGET/package.json" ]; then
      if grep -q '"next"' "$TARGET/package.json" 2>/dev/null; then
        FRAMEWORK="Next.js"
      elif grep -q '"react"' "$TARGET/package.json" 2>/dev/null; then
        FRAMEWORK="React"
      elif grep -q '"vue"' "$TARGET/package.json" 2>/dev/null; then
        FRAMEWORK="Vue"
      elif grep -q '"express"' "$TARGET/package.json" 2>/dev/null; then
        FRAMEWORK="Express"
      else
        FRAMEWORK="—"
      fi
    fi
    SRC_DIR=$( [ -d "$TARGET/src" ] && echo "$TARGET/src" || echo "$TARGET" )
    ;;
  python)
    LANG="Python"
    FRAMEWORK="—"
    SRC_DIR="$TARGET"
    ;;
  go)
    LANG="Go"
    FRAMEWORK="—"
    SRC_DIR="$TARGET"
    ;;
  rust)
    LANG="Rust"
    FRAMEWORK="—"
    SRC_DIR="$TARGET"
    ;;
esac

echo "  语言: ${LANG:-未检测到}"
echo "  构建: ${BUILD_TOOL:-未检测到}"
echo "  框架: ${FRAMEWORK:-未检测到}"
echo "  ORM:  ${ORM:-未检测到}"
echo "  数据库: ${DB_TYPE:-未检测到}"
echo "  源码: ${SRC_DIR:-未检测到}"
echo ""

# ============================================================
# Step 1: 勘探
# ============================================================

echo "----------------------------------------"
echo " Step 1: 勘探（Reconnaissance）"
echo "----------------------------------------"

# 目录结构
echo "  读取目录结构..."
if command -v tree &>/dev/null; then
  tree -L 2 -I 'node_modules|.git|target|build|dist|asset-docs' "$TARGET" 2>/dev/null | head -40
else
  find "$TARGET" -maxdepth 2 -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/target/*' -not -path '*/build/*' -not -path '*/dist/*' 2>/dev/null | sort | head -40
fi
echo ""

# Controller 计数
CTRL_COUNT=0
CTRL_FILES=""
if [ -n "$SRC_DIR" ] && [ -d "$SRC_DIR" ]; then
  CTRL_FILES=$(find "$SRC_DIR" -name "*Controller*.java" -not -path "*/test/*" 2>/dev/null || true)
  CTRL_COUNT=$(echo "$CTRL_FILES" | grep -c "Controller" 2>/dev/null || echo 0)
fi
echo "  Controller 文件: $CTRL_COUNT"

# Service 计数
SVC_COUNT=$(find "$SRC_DIR" -name "*Service*.java" -not -name "*Controller*" -not -path "*/test/*" 2>/dev/null | wc -l | tr -d ' ')
echo "  Service 文件:    $SVC_COUNT"

# Mapper 计数
MAPPER_COUNT=0
if [ -d "$SRC_DIR" ]; then
  MAPPER_COUNT=$(find "$SRC_DIR" -name "*Mapper*.java" -not -path "*/test/*" 2>/dev/null | wc -l | tr -d ' ')
fi
echo "  Mapper 文件:     $MAPPER_COUNT"

# XML Mapper 计数
XML_MAPPER_COUNT=0
if [ -d "$TARGET/src/main/resources" ]; then
  XML_MAPPER_COUNT=$(find "$TARGET/src/main/resources" -name "*.xml" -path "*mapper*" 2>/dev/null | wc -l | tr -d ' ')
fi
echo "  XML Mapper:      $XML_MAPPER_COUNT"

# Entity/Model 计数
ENTITY_COUNT=$(find "$SRC_DIR" -name "*.java" 2>/dev/null | xargs grep -lE "@Entity|@Table" 2>/dev/null | grep -v "test/" | wc -l | tr -d ' ')
echo "  Entity/Model:    $ENTITY_COUNT"

# 端点计数（估计）
ENDPOINT_COUNT=0
if [ -n "$SRC_DIR" ] && [ -d "$SRC_DIR" ]; then
  ENDPOINT_COUNT=$(find "$SRC_DIR" -name "*.java" -not -path "*/test/*" 2>/dev/null | \
    xargs grep -ohP '@(Get|Post|Put|Delete|Patch|Request)Mapping[^)]*' 2>/dev/null | wc -l | tr -d ' ')
fi
echo "  API 端点（估计）: $ENDPOINT_COUNT"

echo ""

# ============================================================
# Step 2: 分类
# ============================================================

echo "----------------------------------------"
echo " Step 2: 分类（Classification）"
echo "----------------------------------------"

# 前端检测
HAS_FRONTEND=false
FRONTEND_FRAMEWORK=""
FE_COUNT=$(find "$TARGET" -name '*.vue' -o -name '*.jsx' -o -name '*.tsx' -o -name '*.html' 2>/dev/null | grep -v node_modules | wc -l | tr -d ' ')
if [ "$FE_COUNT" -gt 0 ]; then
  HAS_FRONTEND=true
  if find "$TARGET" -name '*.vue' 2>/dev/null | grep -v node_modules | head -1 | grep -q .; then
    FRONTEND_FRAMEWORK="Vue"
  elif find "$TARGET" -name '*.jsx' -o -name '*.tsx' 2>/dev/null | grep -v node_modules | head -1 | grep -q .; then
    FRONTEND_FRAMEWORK="React"
  else
    FRONTEND_FRAMEWORK="Vanilla"
  fi
fi

echo "  前端文件数: $FE_COUNT"
echo "  前端框架:   ${FRONTEND_FRAMEWORK:-N/A}"
echo "  有前端:     $HAS_FRONTEND"
echo ""

# 资产覆盖决策
echo "  资产覆盖决策："

# 纯后端跳过前端资产
SKIP_FRONTEND=false
if [ "$HAS_FRONTEND" = false ]; then
  SKIP_FRONTEND=true
  echo "  | 07 | 前端页面 | 占位 | 无前端代码 |"
  echo "  | 08 | 前端状态 | 占位 | 无前端代码 |"
  echo "  | 09 | 静态多端 | 占位 | 无前端代码 |"
else
  echo "  | 07 | 前端页面 | 生成 | 检测到 $FE_COUNT 个前端文件 |"
  echo "  | 08 | 前端状态 | 生成 | 检测到前端框架 |"
  echo "  | 09 | 静态多端 | 生成 | 检测到前端框架 |"
fi

echo "  | 00 | 文档索引 | 生成 | 编排者聚合阶段产出 |"
echo "  | 01 | 系统总览 | 生成 | 编排者聚合阶段产出 |"
echo "  | 02 | 数据模型 | 生成 | Phase 1 Worker A |"
echo "  | 03 | Controller | 生成 | Phase 1 Worker A |"
echo "  | 04 | Mapper | 生成 | Phase 1 Worker A |"
echo "  | 05 | 服务逻辑 | 生成 | Phase 2 Worker C |"
echo "  | 06 | 安全认证 | 生成 | Phase 1 Worker B |"
echo "  | 10 | 业务流图 | 生成 | Phase 3 Worker C (10a+10b) |"
echo "  | 11 | 技术债 | 生成 | Phase 4 Worker B |"
echo "  | 12 | 修复建议 | 生成 | Phase 4 Worker D (派生自 11) |"
echo "  | 13 | 反模式 | 生成 | Phase 4 Worker B |"

echo ""

# 10 拆分决策（v2.6）
SPLIT_10=false
if [ "$CTRL_COUNT" -gt 50 ] || [ "$ENDPOINT_COUNT" -gt 200 ]; then
  SPLIT_10=true
  echo "  10a/10b 拆分: 是（Ctrl=$CTRL_COUNT > 50 或 端点=$ENDPOINT_COUNT > 200）"
else
  echo "  10a/10b 拆分: 否（Ctrl=$CTRL_COUNT ≤ 50, 端点=$ENDPOINT_COUNT ≤ 200）"
fi

echo ""

# ---- 生成 .phase-facts.md ----

mkdir -p "$OUTPUT_DIR"

cat > "$OUTPUT_DIR/.phase-facts.md" << PHASEFACTS
# Phase Facts — $MODULE_NAME

> 自动生成时间：$GEN_TIME
> 管线版本：v3.5
> 脚本：scripts/v35-pipeline.sh

## 规模检测

| 维度 | 值 |
|------|-----|
| 项目类型 | $PROJECT_TYPE |
| 模式 | $MODE |
| 规模 | $SCALE_LEVEL |
| 分层抽样 | $SAMPLING |
| Java 文件数 | $JAVA_COUNT |
| Java 行数 | $JAVA_LOC |

## 技术栈

| 维度 | 值 |
|------|-----|
| 语言 | ${LANG:-—} |
| 构建工具 | ${BUILD_TOOL:-—} |
| 框架 | ${FRAMEWORK:-—} |
| ORM | ${ORM:-—} |
| 数据库 | ${DB_TYPE:-—} |

## 勘探结果

| 维度 | 数量 |
|------|:----:|
| Controller 文件 | $CTRL_COUNT |
| Service 文件 | $SVC_COUNT |
| Mapper 文件 | $MAPPER_COUNT |
| XML Mapper | $XML_MAPPER_COUNT |
| Entity/Model | $ENTITY_COUNT |
| API 端点（估计） | $ENDPOINT_COUNT |
| 前端文件 | $FE_COUNT |

## 分类决策

| 资产 | 决策 |
|------|:----:|
PHASEFACTS

for num in 00 01 02 03 04 05 06 07 08 09 10 11 12 13; do
  if [ "$SKIP_FRONTEND" = true ] && { [ "$num" = "07" ] || [ "$num" = "08" ] || [ "$num" = "09" ]; }; then
    echo "| $num | 占位 |" >> "$OUTPUT_DIR/.phase-facts.md"
  else
    echo "| $num | 生成 |" >> "$OUTPUT_DIR/.phase-facts.md"
  fi
done

cat >> "$OUTPUT_DIR/.phase-facts.md" << PHASEFACTS2

## Pipeline 状态

| Phase | 状态 | Worker 数 |
|-------|:----:|:---------:|
| Phase 1 | pending | $([ "$HAS_FRONTEND" = true ] && echo "7" || echo "4") |
| Phase 2 | pending | 1 |
| Phase 3 | pending | $([ "$SPLIT_10" = true ] && echo "2 (10a+10b)" || echo "1") |
| Phase 4 | pending | 2 (11+13→12) |
| 聚合 | pending | 编排者 (01+00) |
PHASEFACTS2

echo "  .phase-facts.md 已写入: $OUTPUT_DIR/.phase-facts.md"
echo ""

# ============================================================
# 就绪检查
# ============================================================

echo "================================================"
echo " 准备就绪"
echo "================================================"
echo ""
echo " Step -1/0/1/2 已完成。以下数据已提取："
echo ""

printf "  %-20s %s\n" "规模：" "${SCALE_LEVEL}"
printf "  %-20s %s\n" "模式：" "${MODE}"
printf "  %-20s %s\n" "分层抽样：" "${SAMPLING}"
printf "  %-20s %s\n" "Java 文件：" "${JAVA_COUNT}"
printf "  %-20s %s\n" "端点：" "${ENDPOINT_COUNT}"
printf "  %-20s %s\n" "Controller：" "${CTRL_COUNT}"
printf "  %-20s %s\n" "Service：" "${SVC_COUNT}"
printf "  %-20s %s\n" "Mapper：" "${MAPPER_COUNT}"
printf "  %-20s %s\n" "Entity：" "${ENTITY_COUNT}"
printf "  %-20s %s\n" "前端：" "${FRONTEND_FRAMEWORK:-N/A} ($FE_COUNT 文件)"
printf "  %-20s %s\n" "Phase 1 Workers：" "$([ "$HAS_FRONTEND" = true ] && echo "7 (02/03/04/06/07/08/09)" || echo "4 (02/03/04/06)")"

echo ""
echo "  状态文件: $OUTPUT_DIR/.phase-facts.md"

# 检查 init-asset-docs.sh 是否已跑
if [ ! -f "$OUTPUT_DIR/CHANGELOG.md" ]; then
  echo ""
  echo "  ⚠️  资产目录未初始化。运行："
  echo "    bash $SKILL_HOME/scripts/init-asset-docs.sh $TARGET"
else
  echo "  ✓ 资产目录已初始化"
fi

echo ""
echo "  --- Phase 1 Worker Spawn 就绪 ---"
echo ""
echo "  编排者：请按以下顺序 spawn Phase 1 workers："
echo ""

if [ "$HAS_FRONTEND" = true ]; then
  cat << SPAWN_7
  1. Worker A (02-数据模型)    → 变体 Extract
  2. Worker A (03-Controller)   → 变体 Extract
  3. Worker A (04-Mapper)       → 变体 Extract
  4. Worker B (06-安全认证)     → 变体 Analyze
  5. Worker A (07-前端页面)     → 变体 Extract
  6. Worker A (08-前端状态)     → 变体 Extract
  7. Worker A (09-静态多端)     → 变体 Extract

  全部 run_in_background: true，同时启动后等待全部完成。
SPAWN_7
else
  cat << SPAWN_4
  1. Worker A (02-数据模型)     → 变体 Extract
  2. Worker A (03-Controller)   → 变体 Extract
  3. Worker A (04-Mapper)       → 变体 Extract
  4. Worker B (06-安全认证)     → 变体 Analyze

  全部 run_in_background: true，同时启动后等待全部完成。
  07/08/09 跳过（纯后端项目，无前端代码）。
SPAWN_4
fi

echo ""
echo "  Worker Prompt 模板见: $SKILL_HOME/references/parallel-mode.md §D"
echo "  规模约束: $([ "$MODE" = "v3.5" ] && echo "Read ≤ 80 文件/worker（分层抽样）" || echo "Read ≤ 200 文件（全量）")"
echo ""
echo "  完成后：编排者读取 .phase-facts.md 进入 Phase 2"
echo ""
echo "================================================"
