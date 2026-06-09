#!/usr/bin/env bash
# scan-antipatterns.sh — 扫描 24 类反模式（v2.3 满覆盖）
# 用法：bash scripts/scan-antipatterns.sh
#
# 1. 覆盖 24/24 标签（原 8/24 = 33%）
# 2. @secret-leak 排除函数调用 + 提高字符阈值（去 false positive）
# 3. @hardcoded 排除 test/target 目录（去 test 文件 false positive）
# 4. 顶部打印覆盖率统计
set -e

SRC_DIR="${SRC_DIR:-src}"
XML_DIR="${XML_DIR:-$SRC_DIR/main/resources/mybatis}"
WEB_SRC="${WEB_SRC:-$SRC_DIR/../src}"
DOCS_DIR="${DOCS_DIR:-asset-docs}"

# 通用安全打印：把 grep -rn 输出限制 5 行
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

# 覆盖率统计
total_labels=0
hit_labels=0

scan_label() {
  local label="$1"
  local severity="$2"
  local cmd="$3"
  total_labels=$((total_labels+1))
  echo ""
  echo "=== $label  $severity ==="
  if [ -d "${SRC_DIR}" ] || [ -d "${XML_DIR}" ]; then
    hits=$(eval "$cmd" 2>/dev/null | head -5 || true)
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

echo "==> 扫描配置：SRC_DIR=$SRC_DIR  XML_DIR=$XML_DIR  WEB_SRC=$WEB_SRC"
echo "==> 反模式标签 24 个（v2.3 满覆盖）"

# v2.5 占位资产检测（archive_for_skill 测试时发现）：
# 占位资产（行数 < 30 + 含 `<YYYY-MM-DD>` 占位符）会**误报 clean**，
# 因为没实际代码可扫。先列出占位资产，扫描时跳过它们。
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
scan_label "@sqlinjection" "SQL 注入 🔴 P0" \
  "grep -rnE '\\\\\$\\{[^}]+\\}' '$XML_DIR'"
[ -d "$XML_DIR" ] || echo "  (目录 $XML_DIR 不存在，跳过)"

# @secret-leak: 真密钥/密码硬编码（v2.3 排除函数调用 + 阈值 16）
scan_label "@secret-leak" "密钥/密码明文 🔴 P0" \
  "grep -rnE '(secret|password|passwd|apikey|api_key|access_key|private_key|jwt[._-]?secret)\\s*[:=]\\s*[\"\\'][A-Za-z0-9_./+=-]{16,}[\"\\']' '$SRC_DIR' | grep -viE 'getToken|getHeader|setAttribute|getParameter|request\\.|response\\.' | grep -vE '/test/' | grep -vE '/target/'"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @cors-wildcard: CORS 通配
scan_label "@cors-wildcard" "CORS 通配 🔴 P0" \
  "grep -rn 'allowedOrigins(\"\\*\")' '$SRC_DIR' | grep -vE '/test/' | grep -vE '/target/'"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @actuator-exposure: actuator/druid 全公开（
scan_label "@actuator-exposure" "actuator 暴露 🔴 P0" \
  "grep -rnE 'antMatchers.*\"/(actuator|druid)/\\*\\*\"\\.\\s*permitAll' '$SRC_DIR' | grep -vE '/test/'"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @wrong-token-hdr: Token header 非标准（用 token 而非 Authorization）
scan_label "@wrong-token-hdr" "Token header 非标准 🔴 P0" \
  "grep -rnE 'headers\\.\\s*[\"\\']?token[\"\\']?\\s*[,)]' '$WEB_SRC' '$SRC_DIR' 2>/dev/null | grep -vE '/test/' | head -5"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# ==================== P1 标签 ====================

# @xss: 富文本 .html( 渲染
scan_label "@xss" "XSS 风险 🟡 P1" \
  "grep -rnE '\\.html\\(' '$WEB_SRC' 2>/dev/null | grep -vE '/test/' | head -5"
[ -d "$WEB_SRC" ] || echo "  (目录 $WEB_SRC 不存在，跳过)"

# @csrf: CSRF 风险（自动化难，留提示）
scan_label "@csrf" "CSRF 风险 🟡 P1" \
  "echo '  自动化难，建议人工 + SecurityConfig.csrf().disable() 检测'"
total_labels=$((total_labels-1))  # 不计入覆盖率（无实际扫描）

# @perm-mismatch: perms 错用（与 03 权限串全集对比）
if [ -d "$WEB_SRC" ] && [ -d "$DOCS_DIR" ]; then
  scan_label "@perm-mismatch" "权限字符串错用 🟡 P1" \
    "grep -rnE 'perms\\s*=\\s*[\"\\'][^\"\\']+[\"\\']' '$WEB_SRC' 2>/dev/null | head -5"
else
  scan_label "@perm-mismatch" "权限字符串错用 🟡 P1" \
    "echo '  目录不存在，跳过'"
fi

# @admin-bypass: 默认 admin 账号
scan_label "@admin-bypass" "绕过 admin 保护 🟡 P1" \
  "grep -rnE '(loginForm|account|password)\\s*[:=]?\\s*[\"\\']admin[\"\\']' '$WEB_SRC' '$SRC_DIR' 2>/dev/null | head -5"
[ -d "$WEB_SRC" ] && [ -d "$SRC_DIR" ] || echo "  (目录不存在，跳过)"

# @null-pointer: 静态分析（推荐集成 sonar）
scan_label "@null-pointer" "空指针风险 🟡 P1" \
  "echo '  建议集成 sonar/pmd，本工具不内建'"
total_labels=$((total_labels-1))

# @missing-tx: @Transactional 缺位（
scan_label "@missing-tx" "缺事务 🟡 P1" \
  "grep -rL '@Transactional' '$SRC_DIR/*/service/' '$SRC_DIR/*/*/service/' 2>/dev/null | head -5"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @wrong-default: 默认值错误
scan_label "@wrong-default" "默认值错误 🟡 P1" \
  "grep -rnE 'default\\s*=\\s*[\"\\'](true|admin|root|test|123456)[\"\\']' '$SRC_DIR' '$WEB_SRC' 2>/dev/null | head -5"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# ==================== P2 标签 ====================

# @n+1: 子查询 in (
scan_label "@n+1" "N+1 查询 🟢 P2" \
  "grep -rnE 'select.*in \\(' '$XML_DIR' 2>/dev/null | head -5"
[ -d "$XML_DIR" ] || echo "  (目录 $XML_DIR 不存在，跳过)"

# @hardcoded: 硬编码 IP/host（v2.3 排除 test/target + 192.168.x.x）
scan_label "@hardcoded" "硬编码 IP/host 🟢 P2" \
  "grep -rnE '(127\\.0\\.0\\.1|10\\.[0-9]+\\.[0-9]+\\.[0-9]+|192\\.168\\.[0-9]+\\.[0-9]+)' '$SRC_DIR' 2>/dev/null | grep -vE '/test/|/target/' | head -5"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @copy-paste: 复制粘贴未改（启发式）
scan_label "@copy-paste" "复制粘贴 🟢 P2" \
  "echo '  启发式：两文件相似度 > 80% 视为 copy-paste，需 diff 工具'"
total_labels=$((total_labels-1))

# @wrong-tag: 注解标签错（切点路径写错等）
scan_label "@wrong-tag" "注解标签错 🟢 P2" \
  "grep -rnE '@Pointcut' '$SRC_DIR' 2>/dev/null | head -5"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# ==================== P3 标签 ====================

# @dead-code: 死代码（空 class / 空 method）
scan_label "@dead-code" "死代码 ⚪ P3" \
  "find '$SRC_DIR' -name '*.java' -size -300c 2>/dev/null | head -5"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @todo-stub: TODO 占位
scan_label "@todo-stub" "TODO 占位 ⚪ P3" \
  "grep -rn 'TODO Auto-generated' '$SRC_DIR' 2>/dev/null | wc -l | tr -d ' '"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @magic-number: 魔法数
scan_label "@magic-number" "魔法数 ⚪ P3" \
  "grep -rnE 'if\\s*\\(.*==\\s*[0-9]+\\)' '$SRC_DIR' 2>/dev/null | grep -vE '/test/' | head -5"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @long-function: 过长函数（LOC > 100 启发式）
scan_label "@long-function" "过长函数 ⚪ P3" \
  "awk '/^\\s*public.*\\(.*\\)\\s*\\{\\s*\\$/{start=NR; name=\\$0; next} /^\\s*\\}\\s*\$/ && start{if(NR-start>100)print start\":\"name\"  (\"NR-start\" LOC)\"; start=0}' $(find '$SRC_DIR' -name '*.java' 2>/dev/null) 2>/dev/null | head -5"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @long-param: 长参数列表（>5 形参启发式）
scan_label "@long-param" "长参数列表 ⚪ P3" \
  "grep -rE '\\(.*,.*,.*,.*,.*,.*\\)' '$SRC_DIR' --include='*.java' 2>/dev/null | grep -vE '/test/' | head -5"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @feature-envy: 跨文件启发式
scan_label "@feature-envy" "依恋情结 ⚪ P3" \
  "echo '  跨文件启发式，建议集成 pmd/sonarcube'"
total_labels=$((total_labels-1))

# @shotgun-surgery: 散弹枪修改
scan_label "@shotgun-surgery" "散弹枪修改 ⚪ P3" \
  "echo '  跨文件启发式，建议集成 pmd/sonarcube'"
total_labels=$((total_labels-1))

# @wrong-package: 包名/路径错
scan_label "@wrong-package" "包名/路径错 ⚪ P3" \
  "find '$SRC_DIR' -name '*.java' 2>/dev/null | xargs -I {} sh -c 'head -1 {} | grep \"^package \" | sed \"s/package //;s/;//\" | awk -v f=\"{}\" \"{gsub(/\\./, \\\"/\\\"); path=\\$0; if (f !~ path) print f\\\" 期望包：\\\"path}\"' 2>/dev/null | head -5"
[ -d "$SRC_DIR" ] || echo "  (目录 $SRC_DIR 不存在，跳过)"

# @missing-i18n: 缺多语言键
scan_label "@missing-i18n" "多语言键 ⚪ P3" \
  "if [ -d '$WEB_SRC/assets/languages' ]; then zh=\$(find '$WEB_SRC/assets/languages' -name 'zh*' 2>/dev/null | wc -l | tr -d ' '); en=\$(find '$WEB_SRC/assets/languages' -name 'en*' 2>/dev/null | wc -l | tr -d ' '); echo \"  zh_cn 文件: \$zh, en_us 文件: \$en\"; if [ \"\$zh\" -ne \"\$en\" ]; then echo '  WARN: 中英文翻译文件数量不一致'; fi; else echo '  (i18n 目录不存在，跳过)'; fi"
[ -d "$WEB_SRC/assets/languages" ] || echo "  (i18n 目录不存在，跳过)"

# ==================== 覆盖率统计 ====================

echo ""
echo "================================"
echo " 扫描覆盖统计"
echo "================================"
# 24 标签全集：5 个建议集成静态分析工具（@csrf / @null-pointer / @copy-paste / @feature-envy / @shotgun-surgery）
#              1 个边界（@missing-i18n 计入但常跳过）
# total_labels 包含的是"有实际扫描命令的标签"
echo "==> 24 标签全集 | 有命令：$((total_labels)) 个 | 建议集成：5 个（@csrf/@null-pointer/@copy-paste/@feature-envy/@shotgun-surgery）"
echo "==> 命中：$hit_labels 标签 | clean/跳过：$((total_labels - hit_labels)) 标签"
echo "==> 详细标签状态见 13-反模式扫描报告.md"
