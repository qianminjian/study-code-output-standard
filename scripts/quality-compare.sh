#!/usr/bin/env bash
# quality-compare.sh — 模块质量对比自动化
# 用法：bash scripts/quality-compare.sh <project-root> [modules...]
#
# 从各模块 asset-docs/01-系统总览.md 提取关键数字（Controller 数/端点/SQL/Entity/业务流/技术债P0）
# 生成 Markdown 对比表，输出到 stdout
#
# 参数：
#   <project-root>    项目根目录，包含多个子模块
#   [modules...]      可选，指定模块列表；不传则自动扫描 project-root 下的子目录
#
# 输出：
#   Markdown 格式的模块质量对比表，含 P0 风险排序

set -e

PROJECT_ROOT="${1:-}"
if [ -z "$PROJECT_ROOT" ]; then
  echo "用法：bash scripts/quality-compare.sh <project-root> [modules...]"
  echo ""
  echo "示例："
  echo "  bash scripts/quality-compare.sh ~/projects/my-app"
  echo "  bash scripts/quality-compare.sh ~/projects/monorepo module-a module-b module-c"
  exit 1
fi

PROJECT_ROOT="$(cd "$PROJECT_ROOT" 2>/dev/null && pwd || echo "$PROJECT_ROOT")"
if [ ! -d "$PROJECT_ROOT" ]; then
  echo "ERROR: 项目根目录不存在: $PROJECT_ROOT"
  exit 1
fi

shift  # 消费第一个参数

# ---- 模块发现 ----
MODULES=()
if [ $# -gt 0 ]; then
  MODULES=("$@")
else
  # 自动发现：找 asset-docs/ 子目录
  for d in "$PROJECT_ROOT"/*/asset-docs; do
    if [ -f "$d/01-系统总览.md" ]; then
      MODULES+=("$(basename "$(dirname "$d")")")
    fi
  done
  if [ ${#MODULES[@]} -eq 0 ]; then
    echo "WARN: 未自动发现任何含 asset-docs/01-系统总览.md 的模块"
    echo "  请手动指定模块名：bash scripts/quality-compare.sh <project-root> <module1> <module2> ..."
    exit 1
  fi
fi

# ---- 提取函数 ----

# 从 01-系统总览.md 的 §7 数字一览表格中提取数值
extract_number() {
  local file="$1"
  local label="$2"
  awk -F '|' -v label="$label" '
    /## 7\. 数字一览/,/^## [89]/ {
      # 结束条件：下一个 ## 章节
      if ($0 ~ /^## [89]/) exit
      # 匹配表格行：| 标签 | 数值 |
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3)
      if ($2 ~ label) {
        val = $3
        gsub(/[^0-9]/, "", val)
        if (val == "") val = "0"
        print val
        exit
      }
    }
  ' "$file"
}

# 从 §3 技术栈表格提取技术名称
extract_tech() {
  local file="$1"
  local dim_label="$2"
  if [ ! -f "$file" ]; then
    echo ""
    return
  fi
  awk -F '|' -v lbl="$dim_label" '
    /## 3\. 技术栈/,/^## [45]/ {
      if ($0 ~ /^## [45]/) exit
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3)
      if ($2 ~ lbl) {
        val = $3
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
        # 提取主要技术名（去掉版本号）
        sub(/<.*/, "", val)
        if (val == "" || val ~ /^</) val = ""
        print val
        exit
      }
    }
  ' "$file"
}

# 获取项目语言/运行时
extract_language() {
  local file="$1"
  local runtime
  runtime=$(extract_tech "$file" "运行时")
  [ -n "$runtime" ] && echo "$runtime" && return
  # fallback: 检查 pom.xml / package.json
  local mod_dir
  mod_dir=$(dirname "$(dirname "$file")")
  if [ -f "$mod_dir/pom.xml" ]; then
    echo "Java"
  elif [ -f "$mod_dir/package.json" ]; then
    echo "Node.js"
  else
    echo ""
  fi
}

# ---- 数据收集 ----

declare -a RESULTS
HEADER_PRINTED=false

collect_module() {
  local mod_name="$1"
  local overview="$PROJECT_ROOT/$mod_name/asset-docs/01-系统总览.md"

  if [ ! -f "$overview" ]; then
    # 尝试其他可能的命名
    local found
    found=$(find "$PROJECT_ROOT/$mod_name" -name "01-*系统总览*" -o -name "01-*overview*" 2>/dev/null | head -1)
    if [ -z "$found" ]; then
      echo "WARN: 模块 $mod_name 缺少 01-系统总览.md，跳过"
      return
    fi
    overview="$found"
  fi

  local ctrl svc mapper model db_tables endpoints
  local frontend_comps todos p0_bugs
  local language orm framework

  ctrl=$(extract_number "$overview" "Controller")
  svc=$(extract_number "$overview" "Service")
  mapper=$(extract_number "$overview" "Mapper")
  model=$(extract_number "$overview" "Model")
  db_tables=$(extract_number "$overview" "数据库表")
  endpoints=$(extract_number "$overview" "API 端点")
  frontend_comps=$(extract_number "$overview" "前端组件")
  todos=$(extract_number "$overview" "TODO")
  p0_bugs=$(extract_number "$overview" "已知 Bug")

  language=$(extract_language "$overview")
  orm=$(extract_tech "$overview" "ORM")
  framework=$(extract_tech "$overview" "Web")

  # 默认值
  ctrl=${ctrl:-0}
  svc=${svc:-0}
  mapper=${mapper:-0}
  model=${model:-0}
  db_tables=${db_tables:-0}
  endpoints=${endpoints:-0}
  frontend_comps=${frontend_comps:-0}
  todos=${todos:-0}
  p0_bugs=${p0_bugs:-0}
  language=${language:-—}
  orm=${orm:-—}
  framework=${framework:-—}

  # 计算健康度指标
  local assets_total p0_density
  assets_total=$((ctrl + svc + mapper + model + db_tables))
  if [ "$endpoints" -gt 0 ]; then
    p0_density=$(awk "BEGIN { printf \"%.2f\", ($p0_bugs / $endpoints) * 100 }")
  else
    p0_density="0.00"
  fi

  RESULTS+=("$mod_name|$language|$framework|$orm|$ctrl|$svc|$mapper|$model|$db_tables|$endpoints|$frontend_comps|$todos|$p0_bugs|$p0_density")
}

for mod in "${MODULES[@]}"; do
  collect_module "$mod"
done

if [ ${#RESULTS[@]} -eq 0 ]; then
  echo "ERROR: 没有成功提取任何模块数据"
  exit 1
fi

# ---- 输出 Markdown 对比表 ----

GEN_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "## 模块质量对比"
echo ""
echo "> 生成时间：$GEN_TIME"
echo "> 数据源：各模块 \`asset-docs/01-系统总览.md\` §7 数字一览"
echo "> 脚本：\`scripts/quality-compare.sh\`"
echo ""
echo "### 数字一览"
echo ""
echo "| 模块 | 语言 | 框架 | ORM | Ctrl | Svc | Mapper | Model | 表 | 端点 | 前端 | TODO | P0 Bug |"
echo "|------|------|------|-----|:----:|:---:|:------:|:-----:|:---:|:----:|:----:|:----:|:------:|"

# 按 P0 Bug 数降序排序
while IFS='|' read -r mod lang fw orm ctrl svc mapper model db endpoints fe todos p0 density; do
  [ -z "$mod" ] && continue
  printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' \
    "$mod" "$lang" "$fw" "$orm" "$ctrl" "$svc" "$mapper" "$model" "$db" "$endpoints" "$fe" "$todos" "$p0"
done < <(printf '%s\n' "${RESULTS[@]}" | sort -t'|' -k13 -nr)

echo ""

# ---- P0 风险排序 ----

echo "### P0 风险排序（按 P0 密度 = P0 Bug / API 端点数）"
echo ""
echo "| 排名 | 模块 | P0 Bug | API 端点 | P0 密度 | 风险等级 |"
echo "|:----:|------|:------:|:--------:|:-------:|:--------:|"

rank=1
while IFS='|' read -r mod lang fw orm ctrl svc mapper model db endpoints fe todos p0 density; do
  [ -z "$mod" ] && continue
  local_risk="🟢 低"
  if [ "$(echo "$density > 5.0" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
    local_risk="🔴 高"
  elif [ "$(echo "$density > 2.0" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
    local_risk="🟡 中"
  fi

  printf '| %s | %s | %s | %s | %.2f%% | %s |\n' \
    "$rank" "$mod" "$p0" "$endpoints" "$density" "$local_risk"
  rank=$((rank + 1))
done < <(printf '%s\n' "${RESULTS[@]}" | sort -t'|' -k14 -nr)

echo ""
echo "---"
echo ""
echo "### 聚合统计"

total_modules=${#RESULTS[@]}
total_ctrl=0; total_svc=0; total_mapper=0; total_endpoints=0; total_p0=0; total_todos=0
for row in "${RESULTS[@]}"; do
  IFS='|' read -r _ _ _ _ ctrl svc mapper _ _ endpoints _ todos p0 _ <<< "$row"
  total_ctrl=$((total_ctrl + ctrl))
  total_svc=$((total_svc + svc))
  total_mapper=$((total_mapper + mapper))
  total_endpoints=$((total_endpoints + endpoints))
  total_p0=$((total_p0 + p0))
  total_todos=$((total_todos + todos))
done

echo "| 指标 | 合计 |"
echo "|------|:----:|"
echo "| 模块总数 | $total_modules |"
echo "| Controller 总数 | $total_ctrl |"
echo "| Service 总数 | $total_svc |"
echo "| Mapper 总数 | $total_mapper |"
echo "| API 端点总数 | $total_endpoints |"
echo "| TODO/FIXME 总数 | $total_todos |"

if [ "$total_endpoints" -gt 0 ]; then
  avg_p0=$(awk "BEGIN { printf \"%.2f\", ($total_p0 / $total_modules) }")
  echo "| P0 Bug 总计 | $total_p0 |"
  echo "| P0 Bug 平均（每模块） | $avg_p0 |"
else
  echo "| P0 Bug 总计 | $total_p0 |"
fi

echo ""
echo "> 数据由 \`scripts/quality-compare.sh\` 自动提取，建议结合 \`scripts/check-consistency.sh\` 交叉验证数字准确性。"
