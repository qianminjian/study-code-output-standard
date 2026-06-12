#!/usr/bin/env bash
# secrets.test.sh — 扫描本仓库，确保无明文密钥/密码
# 用法：bash tests/secrets.test.sh
#
# 策略：
#   - 排除 .internal/（含反例展示 wxcbrc-case.md）
#   - 排除 references/prompts/（代码示例，含 token/password 变量名）
#   - 排除 .git/、tests/、node_modules/
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 1. 扫常见密钥模式（YAML / 等号 / 引号变种）
# 排除 references/ 目录（prompts 含代码示例，methodology 含反例展示）
echo "[T1] 扫描 secret/password/token/apikey 明文赋值"
HITS=$(grep -rnE "(secret|password|passwd|token|apikey|api_key|access_key|private_key|jwt[._-]?secret)\s*[:=]\s*[\"']?[A-Za-z0-9_./+=-]{6,}[\"']?" \
  "$REPO_ROOT" \
  --include="*.md" --include="*.sh" --include="*.ps1" --include="*.yml" --include="*.yaml" --include="*.properties" \
  --exclude-dir=".git" --exclude-dir="tests" --exclude-dir="node_modules" --exclude-dir=".v3.5-test" --exclude-dir=".v3.0-test" --exclude-dir="_proc-use" --exclude-dir=".internal" --exclude-dir="references" \
  2>/dev/null || true)

# 过滤：仅保留真实可疑行（去除 <REDACTED> / 注释 / 反例 / 表格内）
SUSPICIOUS=$(echo "$HITS" \
  | grep -vE "<REDACTED>|//.*密钥|⚠️|测试|example|placeholder|反例|参考案例|占位|abstracted|REDACTED" \
  | grep -vE "^\s*#|^\s*//|^\s*\*" \
  | head -20 || true)

if [ -n "$SUSPICIOUS" ]; then
  echo "FAIL: 检出疑似明文密钥："
  echo "$SUSPICIOUS"
  exit 1
fi
echo "  ✓ 未发现明文密钥"

# 2. 扫 .internal/examples/wxcbrc-case.md 中的密钥"huawei"明文（应已脱敏为占位）
echo "[T2] 校验 wxcbrc-case.md 中无 'huawei' 真实密钥"
HUAWEI_HITS=$(grep -rn "huawei" "$REPO_ROOT/.internal/examples/wxcbrc-case.md" 2>/dev/null || true)
if [ -n "$HUAWEI_HITS" ]; then
  echo "FAIL: wxcbrc-case.md 含 'huawei' 真实字符串："
  echo "$HUAWEI_HITS"
  exit 1
fi
echo "  ✓ 无 huawei 真实字符串"

# 3. 校验 methodology/07-典型案例与反模式.md 中的密钥占位符（应使用脱敏串）
echo "[T3] 校验 07-典型案例与反模式.md 中密钥占位（应使用 <REDACTED> 或脱敏串）"
SECRET_LITERAL=$(grep -nE 'secret\s*=\s*"[a-zA-Z0-9-]{6,}"' "$REPO_ROOT/references/methodology/07-典型案例与反模式.md" 2>/dev/null || true)
if [ -n "$SECRET_LITERAL" ]; then
  NON_REDACTED=$(echo "$SECRET_LITERAL" | grep -vE "hardcoded-default-secret|<REDACTED>|REDACTED|secret_default|please_change" || true)
  if [ -n "$NON_REDACTED" ]; then
    echo "FAIL: 07 含未脱敏的 secret 字符串："
    echo "$NON_REDACTED"
    exit 1
  fi
fi
echo "  ✓ 反例展示使用脱敏串"

# 4. 校验所有 frontmatter 中无明文密钥值
echo "[T4] 校验方法论 frontmatter 无密钥值"
FM_SECRETS=$(grep -rnE '"data_source".*password|"data_source".*secret' "$REPO_ROOT/references/methodology" --include="*.md" 2>/dev/null || true)
if [ -n "$FM_SECRETS" ]; then
  echo "FAIL: frontmatter data_source 含密钥关键词："
  echo "$FM_SECRETS"
  exit 1
fi
echo "  ✓ frontmatter 干净"

echo ""
echo "==> secrets.test.sh: 全部 4 项通过"
