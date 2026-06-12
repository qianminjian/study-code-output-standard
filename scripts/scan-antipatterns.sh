#!/usr/bin/env bash
# scan-antipatterns.sh — 扫描反模式（v3.0 函数式重构，消除 eval）
# 用法：bash scripts/scan-antipatterns.sh
#
# v3.0 变更：24 个 scan_label "eval" 调用改为函数式调用
# - 每个 scan 定义为独立 bash 函数
# - scan_label 只接受函数名引用
# - @secret-yml 已从外部 workaround 收敛为正规函数
# - 各函数保持与 v2.6 完全相同正则逻辑
set -e

SRC_DIR="${SRC_DIR:-src}"
XML_DIR="${XML_DIR:-$SRC_DIR/main/resources/mybatis}"
WEB_SRC="${WEB_SRC:-$SRC_DIR/../src}"
DOCS_DIR="${DOCS_DIR:-asset-docs}"

# --- 项目根查找（供 @secret-yml 使用） ---
PROJECT_ROOT="$SRC_DIR"
while true; do
  parent=$(dirname "$PROJECT_ROOT")
  [ "$parent" = "/" ] && break
  [ "$parent" = "$PROJECT_ROOT" ] && break  # fixed point guard（如 '.' 的 dirname 仍是 '.'）
  if [ -f "$PROJECT_ROOT/pom.xml" ] && grep -q "<modules>" "$PROJECT_ROOT/pom.xml" 2>/dev/null; then
    break
  fi
  PROJECT_ROOT="$parent"
done

# --- 覆盖率计数器 ---
total_labels=0
hit_labels=0

# --- 通用安全打印（保留原版 scan_grep） ---
scan_grep() {
  local label="$1"
  shift
  local hits
  hits=$("$@" 2>/dev/null | head -5 || true)
  if [ -n "$hits" ]; then
    echo "$hits"
    return 0
  else
    echo "  (clean)"
    return 0
  fi
}

# --- scan_label：接受函数名引用，不再用 eval ---
scan_label() {
  local label="$1"
  local severity="$2"
  local func_name="$3"
  total_labels=$((total_labels+1))
  echo ""
  echo "=== $label  $severity ==="
  if [ -d "${SRC_DIR}" ] || [ -d "${XML_DIR}" ]; then
    local hits
    hits=$("$func_name" 2>/dev/null | head -5 || true)
    if [ -n "$hits" ]; then
      echo "$hits"
      hit_labels=$((hit_labels+1))
    else
      echo "  (clean)"
    fi
  else
    echo "  (目录不存在，跳过)"
  fi
}

# ==================== Scan 函数定义 (24 个) ====================

# --- P0 标签 (6 个) ---

_scan_sqlinjection() {
  grep -rnE '\$\{[^}]+\}' "$XML_DIR" 2>/dev/null | head -5 || true
}

_scan_secret_leak() {
  grep -rnE '(secret|password|passwd|apikey|api_key|access_key|private_key|jwt[._-]?secret)\s*[:=]\s*["\x27][A-Za-z0-9_./+=\-@.!#]{8,}["\x27]' \
    "${SRC_DIR}" 2>/dev/null \
    | grep -viE 'getToken|getHeader|setAttribute|getParameter|request\.|response\.' \
    | grep -vE '/test/' \
    | grep -vE '/target/' \
    | head -5 || true
}

_scan_secret_yml() {
  local result
  result=$(grep -rnE '(secret|password|passwd|apikey|api_key|access_key|private_key).*[A-Za-z0-9_./+=\-@.!#]{8,}' \
    "${PROJECT_ROOT}" --include='*.yml' --include='*.yaml' --include='*.properties' 2>/dev/null \
    | grep -vE '/test/' | head -10)
  if [ -z "$result" ] && [ -d "${PROJECT_ROOT}" ]; then
    result=$(find "${PROJECT_ROOT}" \( -name '*.yml' -o -name '*.yaml' -o -name '*.properties' \) 2>/dev/null \
      | grep -vE '/test/|/target/' \
      | while IFS= read -r f; do
        grep -nE '(secret|password|passwd|apikey|api_key|access_key|private_key).*[A-Za-z0-9_./+=\-@.!#]{8,}' "$f" 2>/dev/null \
          | sed "s|^|${f}:|"
      done | head -10)
  fi
  echo "$result"
}

_scan_cors_wildcard() {
  grep -rn 'allowedOrigins("\*")' "$SRC_DIR" 2>/dev/null \
    | grep -vE '/test/' \
    | grep -vE '/target/' \
    | head -5 || true
}

_scan_actuator_exposure() {
  grep -rnE 'antMatchers.*"/(actuator|druid)/\*\*"\.\s*permitAll' "$SRC_DIR" 2>/dev/null \
    | grep -vE '/test/' \
    | head -5 || true
}

_scan_wrong_token_hdr() {
  grep -rnE 'headers\.\s*["\x27]?token["\x27]?\s*[,)]' "$WEB_SRC" "$SRC_DIR" 2>/dev/null \
    | grep -vE '/test/' \
    | head -5 || true
}

# --- P1 标签 (7 个) ---

_scan_xss() {
  grep -rnE '\.html\(' "$WEB_SRC" 2>/dev/null \
    | grep -vE '/test/' \
    | head -5 || true
}

_scan_csrf() {
  echo '  自动化难，建议人工 + SecurityConfig.csrf().disable() 检测'
}

_scan_perm_mismatch() {
  if [ -d "$WEB_SRC" ] && [ -d "$DOCS_DIR" ]; then
    grep -rnE 'perms\s*=\s*["\x27][^"\x27]+["\x27]' "$WEB_SRC" 2>/dev/null | head -5 || true
  else
    echo '  目录不存在，跳过'
  fi
}

_scan_admin_bypass() {
  grep -rnE '(loginForm|account|password)\s*[:=]?\s*["\x27]admin["\x27]' "$WEB_SRC" "$SRC_DIR" 2>/dev/null \
    | head -5 || true
}

_scan_null_pointer() {
  echo '  建议集成 sonar/pmd，本工具不内建'
}

_scan_missing_tx() {
  grep -rL '@Transactional' "$SRC_DIR"/*/service/ "$SRC_DIR"/*/*/service/ 2>/dev/null | head -5 || true
}

_scan_wrong_default() {
  grep -rnE 'default\s*=\s*["\x27](true|admin|root|test|123456)["\x27]' "$SRC_DIR" "$WEB_SRC" 2>/dev/null \
    | head -5 || true
}

# --- P2 标签 (4 个) ---

_scan_n1() {
  grep -rnE 'select.*in \(' "$XML_DIR" 2>/dev/null | head -5 || true
}

_scan_hardcoded() {
  grep -rnE '(127\.0\.0\.1|10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+)' "$SRC_DIR" 2>/dev/null \
    | grep -vE '/test/|/target/' \
    | head -5 || true
}

_scan_copy_paste() {
  echo '  启发式：两文件相似度 > 80% 视为 copy-paste，需 diff 工具'
}

_scan_wrong_tag() {
  grep -rnE '@Pointcut' "$SRC_DIR" 2>/dev/null | head -5 || true
}

# --- P3 标签 (9 个) ---

_scan_dead_code() {
  find "$SRC_DIR" -name '*.java' -size -300c 2>/dev/null | head -5 || true
}

_scan_todo_stub() {
  grep -rn 'TODO Auto-generated' "$SRC_DIR" 2>/dev/null | wc -l | tr -d ' ' || echo 0
}

_scan_magic_number() {
  grep -rnE 'if\s*\(.*==\s*[0-9]+\)' "$SRC_DIR" 2>/dev/null \
    | grep -vE '/test/' \
    | head -5 || true
}

_scan_long_function() {
  find "$SRC_DIR" -name '*.java' 2>/dev/null \
    | xargs awk '/^\s*public.*\(.*\)\s*\{\s*$/{start=NR; name=$0; next} /^\s*\}\s*$/ && start{if(NR-start>100)print start":"name"  ("NR-start" LOC)"; start=0}' 2>/dev/null \
    | head -5 || true
}

_scan_long_param() {
  grep -rE '\(.*,.*,.*,.*,.*,.*\)' "$SRC_DIR" --include='*.java' 2>/dev/null \
    | grep -vE '/test/' \
    | head -5 || true
}

_scan_feature_envy() {
  echo '  跨文件启发式，建议集成 pmd/sonarcube'
}

_scan_shotgun_surgery() {
  echo '  跨文件启发式，建议集成 pmd/sonarcube'
}

_scan_wrong_package() {
  find "$SRC_DIR" -name '*.java' 2>/dev/null | while IFS= read -r java_file; do
    pkg=$(head -1 "$java_file" 2>/dev/null | grep "^package " | sed 's/package //;s/;//')
    [ -z "$pkg" ] && continue
    expected_path=$(echo "$pkg" | tr '.' '/')
    if ! echo "$java_file" | grep -q "$expected_path"; then
      echo "${java_file} 期望包：${expected_path}"
    fi
  done | head -5
}

_scan_missing_i18n() {
  if [ -d "$WEB_SRC/assets/languages" ]; then
    local zh en
    zh=$(find "$WEB_SRC/assets/languages" -name 'zh*' 2>/dev/null | wc -l | tr -d ' ')
    en=$(find "$WEB_SRC/assets/languages" -name 'en*' 2>/dev/null | wc -l | tr -d ' ')
    echo "  zh_cn 文件: $zh, en_us 文件: $en"
    if [ "$zh" -ne "$en" ]; then
      echo '  WARN: 中英文翻译文件数量不一致'
    fi
  else
    echo '  (i18n 目录不存在，跳过)'
  fi
  return 0
}

# ==================== 主扫描流程 ====================

echo "==> 扫描配置：SRC_DIR=$SRC_DIR  XML_DIR=$XML_DIR  WEB_SRC=$WEB_SRC"
echo "==> 反模式标签 24 个（v3.0 函数式重构，消除 eval）"

# --- 占位资产检测 (v2.5) ---
echo ""
echo "=== 占位资产检测 ==="
placeholder_count=0
if [ -d "$DOCS_DIR" ]; then
  for f in "$DOCS_DIR"/[0-9][0-9]-*.md; do
    [ -f "$f" ] || continue
    lines=$(wc -l < "$f" | tr -d ' ')
    if [ "$lines" -lt 30 ]; then
      echo "  ⚠ $(basename "$f") —— ${lines} 行（占位阈值 30）"
      placeholder_count=$((placeholder_count+1))
    fi
  done
  if [ "$placeholder_count" -gt 0 ]; then
    echo "  → 共 $placeholder_count 篇占位资产（建议先实写再跑 scan 才有意义）"
  else
    echo "  → 无占位资产（全部 ≥ 30 行）"
  fi
else
  echo "  (目录 $DOCS_DIR 不存在，跳过)"
fi
echo ""

# ==================== P0 标签 ====================

# @sqlinjection: ${} 字符串拼接
scan_label "@sqlinjection" "SQL 注入 🔴 P0" _scan_sqlinjection
[ -d "$XML_DIR" ] || echo "  (目录 $XML_DIR 不存在，跳过)"

# @secret-leak: 真密钥/密码硬编码
# v2.6 修复:阈值 16→8(06 worker 验证 CxMtyx@9527. 11 字符漏报)
# 字符类扩展含 @/./!/#/$/ (密码常见字符)+ _/-/+先保留
scan_label "@secret-leak" "密钥/密码明文 🔴 P0" _scan_secret_leak

# @secret-yml: yml/properties 独立扫描（v3.0 已从 workaround 收敛为正规函数）
scan_label "@secret-yml" "密钥/密码明文(yml) 🔴 P0" _scan_secret_yml
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @cors-wildcard: CORS 通配
scan_label "@cors-wildcard" "CORS 通配 🔴 P0" _scan_cors_wildcard
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @actuator-exposure: actuator/druid 全公开
scan_label "@actuator-exposure" "actuator 暴露 🔴 P0" _scan_actuator_exposure
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @wrong-token-hdr: Token header 非标准（用 token 而非 Authorization）
scan_label "@wrong-token-hdr" "Token header 非标准 🔴 P0" _scan_wrong_token_hdr
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# ==================== P1 标签 ====================

# @xs : 富文本 .html( 渲染
scan_label "@xss" "XSS 风险 🟡 P1" _scan_xss
[ -d "$WEB_SRC" ] || echo "  (目录 $WEB_SRC 不存在，跳过)"

# @csrf: CSRF 风险（自动化难，留提示）
scan_label "@csrf" "CSRF 风险 🟡 P1" _scan_csrf
total_labels=$((total_labels-1))  # 不计入覆盖率（无实际扫描）

# @perm-mismatch: perms 错用（与 03 权限串全集对比）
scan_label "@perm-mismatch" "权限字符串错用 🟡 P1" _scan_perm_mismatch

# @admin-bypass: 默认 admin 账号
scan_label "@admin-bypass" "绕过 admin 保护 🟡 P1" _scan_admin_bypass
[ -d "$WEB_SRC" ] && [ -d "$SRC_DIR" ] || echo "  (目录不存在，跳过)"

# @null-pointer: 静态分析（推荐集成 sonar）
scan_label "@null-pointer" "空指针风险 🟡 P1" _scan_null_pointer
total_labels=$((total_labels-1))

# @missing-tx: @Transactional 缺位
scan_label "@missing-tx" "缺事务 🟡 P1" _scan_missing_tx
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @wrong-default: 默认值错误
scan_label "@wrong-default" "默认值错误 🟡 P1" _scan_wrong_default
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# ==================== P2 标签 ====================

# @n+1: 子查询 in (
scan_label "@n+1" "N+1 查询 🟢 P2" _scan_n1
[ -d "$XML_DIR" ] || echo "  (目录 $XML_DIR 不存在，跳过)"

# @hardcoded: 硬编码 IP/host（v2.3 排除 test/target + 192.168.x.x）
scan_label "@hardcoded" "硬编码 IP/host 🟢 P2" _scan_hardcoded
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @copy-paste: 复制粘贴未改（启发式）
scan_label "@copy-paste" "复制粘贴 🟢 P2" _scan_copy_paste
total_labels=$((total_labels-1))

# @wrong-tag: 注解标签错（切点路径写错等）
scan_label "@wrong-tag" "注解标签错 🟢 P2" _scan_wrong_tag
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# ==================== P3 标签 ====================

# @dead-code: 死代码（空 class / 空 method）
scan_label "@dead-code" "死代码 ⚪ P3" _scan_dead_code
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @todo-stub: TODO 占位
scan_label "@todo-stub" "TODO 占位 ⚪ P3" _scan_todo_stub
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @magic-number: 魔法数
scan_label "@magic-number" "魔法数 ⚪ P3" _scan_magic_number
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @long-function: 过长函数（LOC > 100 启发式）
scan_label "@long-function" "过长函数 ⚪ P3" _scan_long_function
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @long-param: 长参数列表（>5 形参启发式）
scan_label "@long-param" "长参数列表 ⚪ P3" _scan_long_param
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @feature-envy: 跨文件启发式
scan_label "@feature-envy" "依恋情结 ⚪ P3" _scan_feature_envy
total_labels=$((total_labels-1))

# @shotgun-surgery: 散弹枪修改
scan_label "@shotgun-surgery" "散弹枪修改 ⚪ P3" _scan_shotgun_surgery
total_labels=$((total_labels-1))

# @wrong-package: 包名/路径错
scan_label "@wrong-package" "包名/路径错 ⚪ P3" _scan_wrong_package
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @missing-i18n: 缺多语言键
scan_label "@missing-i18n" "多语言键 ⚪ P3" _scan_missing_i18n
[ -d "$WEB_SRC/assets/languages" ] || echo "  (i18n 目录不存在，跳过)"

# ==================== 覆盖率统计 ====================

echo ""
echo "================================"
echo " 扫描覆盖统计"
echo "================================"
# 24 标签全集：5 个建议集成静态分析工具（@csrf / @null-pointer / @copy-paste / @feature-envy / @shotgun-surgery）
#              1 个边界（@missing-i18n 计入但常跳过）
# total_labels 包含的是"有实际扫描命令的标签"
echo "==> 24 标签全集（v3.0 函数式重构）| 有命令：$((total_labels)) 个 | 建议集成：5 个（@csrf/@null-pointer/@copy-paste/@feature-envy/@shotgun-surgery）"
echo "==> 命中：$hit_labels 标签 | clean/跳过：$((total_labels - hit_labels)) 标签"
echo "==> 详细标签状态见 13-反模式扫描报告.md"
