#!/usr/bin/env bash
# secrets.test.sh — 扫描本仓库，确保无明文密钥/密码
# 用法：bash tests/secrets.test.sh
#
# 策略：
#   - 排除 wxcbrc-case.md（是反例展示，标"⚠️ P0"或"<REDACTED>"）
#   - 排除 .git/、tests/、docs/scripts/、docs/templates/、docs/ai-prompts/
#   - 排除 line 1-3 上下文（注释/元信息）
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 1. 扫常见密钥模式（YAML / 等号 / 引号变种）
# 排除审计/反例/历史报告文档（这些文档的"密钥"是教学/历史快照，不应算作泄露）：
#   - REVIEW.md（审计报告本身含历史路径/示例）
#   - 输出代码资产的提示词.md（项目原始 prompt）
#   - skill/references/anti-patterns.md（反例展示）
#   - docs/07-典型案例与反模式.md（反例展示）
#   - skill/references/asset-types.md（资产类型说明）
echo "[T1] 扫描 secret/password/token/apikey 明文赋值"
HITS=$(grep -rnE "(secret|password|passwd|token|apikey|api_key|access_key|private_key|jwt[._-]?secret)\s*[:=]\s*[\"']?[A-Za-z0-9_./+=-]{6,}[\"']?" \
  "$REPO_ROOT" \
  --include="*.md" --include="*.sh" --include="*.ps1" --include="*.yml" --include="*.yaml" --include="*.properties" \
  --exclude-dir=".git" --exclude-dir="tests" --exclude-dir="node_modules" \
  --exclude="REVIEW.md" \
  --exclude="输出代码资产的提示词.md" \
  2>/dev/null || true)

# 过滤：仅保留真实可疑行（去除 <REDACTED> / 注释 / 反例 / 表格内）
SUSPICIOUS=$(echo "$HITS" \
  | grep -vE "<REDACTED>|//.*密钥|⚠️|测试|example|placeholder|反例|参考案例|占位|abstracted|REDACTED" \
  | grep -vE "^\s*#|^\s*//|^\s*\*" \
  | grep -vE "wxcbrc-case\.md|anti-patterns\.md|asset-types\.md" \
  | head -20 || true)

if [ -n "$SUSPICIOUS" ]; then
  echo "FAIL: 检出疑似明文密钥："
  echo "$SUSPICIOUS"
  exit 1
fi
echo "  ✓ 未发现明文密钥"

# 2. 扫 docs/examples/wxcbrc-case.md 中的密钥"huawei"明文（应已脱敏为占位）
echo "[T2] 校验 wxcbrc-case.md 中无 'huawei' 真实密钥"
HUAWEI_HITS=$(grep -rn "huawei" "$REPO_ROOT/docs/examples/wxcbrc-case.md" 2>/dev/null || true)
if [ -n "$HUAWEI_HITS" ]; then
  echo "FAIL: wxcbrc-case.md 含 'huawei' 真实字符串："
  echo "$HUAWEI_HITS"
  exit 1
fi
echo "  ✓ 无 huawei 真实字符串"

# 3. 校验 P1-04：07-典型案例与反模式.md 中的密钥占位符（应使用脱敏串，不应保留真实值）
echo "[T3] 校验 07-典型案例与反模式.md 中密钥占位（应使用 <REDACTED> 或脱敏串）"
SECRET_LITERAL=$(grep -nE 'secret\s*=\s*"[a-zA-Z0-9-]{6,}"' "$REPO_ROOT/docs/07-典型案例与反模式.md" 2>/dev/null || true)
if [ -n "$SECRET_LITERAL" ]; then
  # 7 处反例展示：必须是脱敏后的占位符，不应是真实值
  # 接受 hardcoded-default-secret 等"明显脱敏串"
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
FM_SECRETS=$(grep -rnE '"data_source".*password|"data_source".*secret' "$REPO_ROOT/docs" --include="*.md" 2>/dev/null || true)
if [ -n "$FM_SECRETS" ]; then
  echo "FAIL: frontmatter data_source 含密钥关键词："
  echo "$FM_SECRETS"
  exit 1
fi
echo "  ✓ frontmatter 干净"

echo ""
echo "==> secrets.test.sh: 全部 4 项通过"
