#!/usr/bin/env bash
# scan-antipatterns.sh — 扫描常见反模式
# 用法：bash scripts/scan-antipatterns.sh
set -e

SRC_DIR="${SRC_DIR:-src}"
XML_DIR="${XML_DIR:-$SRC_DIR/main/resources/mybatis}"

echo "=== @sqlinjection  SQL 注入风险 ==="
if [ -d "$XML_DIR" ]; then
  grep -rnE "\\$\\{[^}]+\\}" "$XML_DIR" 2>/dev/null | head -5 || echo "  (clean)"
else
  echo "  (目录 $XML_DIR 不存在，跳过)"
fi

echo ""
echo "=== @secret-leak  密钥/密码明文 ==="
# 修复 P2-04：覆盖 3 种常见格式
#   1) 字符串赋值（带/不带引号）：secret = "xxx" / secret='xxx' / secret=xxx
#   2) YAML 冒号格式：        secret: xxx
#   3) 中间空格：             password = 'foo'
# 字符阈值 6+（避免 false positive，如 password=123）
# 排除 test/sample/mock/example
grep -rnE "(secret|password|passwd|token|apikey|api_key|access_key|private_key|jwt[._-]?secret)\\s*[:=]\\s*[\"']?[A-Za-z0-9_./+=-]{6,}[\"']?" \
  "$SRC_DIR" 2>/dev/null \
  | grep -viE "test|sample|mock|example|<.*>|\$\{|placeholder" \
  | head -5 || echo "  (clean)"

echo ""
echo "=== @cors-wildcard  CORS 通配 ==="
grep -rn "allowedOrigins(\"\\*\")" "$SRC_DIR" 2>/dev/null | head -5 || echo "  (clean)"

echo ""
echo "=== @hardcoded  硬编码 IP/host ==="
grep -rnE "(127\\.0\\.0\\.1|10\\.[0-9]+\\.[0-9]+\\.[0-9]+|192\\.168\\.[0-9]+\\.[0-9]+)" \
  "$SRC_DIR" 2>/dev/null | head -5 || echo "  (clean)"

echo ""
echo "=== @actuator-exposure  actuator 暴露 ==="
# 修复 P2-02：只匹配"真正暴露"配置（exposure.include=* 或 @RestControllerEndpoint）
# 避免任何 "actuator" 字符串引用都误报
grep -rnE "exposure\\.include\\s*[:=]\\s*[\"']?\\*" \
  "$SRC_DIR" 2>/dev/null | head -5 || echo "  (clean)"
grep -rn "@RestControllerEndpoint\\|@Endpoint.*(read|write)\\s*=" \
  "$SRC_DIR" 2>/dev/null | head -5 || true
if ! grep -rqE "exposure\\.include\\s*[:=]\\s*[\"']?\\*|@RestControllerEndpoint" "$SRC_DIR" 2>/dev/null; then
  echo "  (no full actuator exposure)"
fi

echo ""
echo "=== @todo-stub  TODO 占位 ==="
grep -rn "TODO Auto-generated" "$SRC_DIR" 2>/dev/null | wc -l | tr -d ' '

echo ""
echo "=== @missing-i18n  多语言键检查 ==="
if [ -d "$SRC_DIR/../src/assets/languages" ]; then
  zh=$(find "$SRC_DIR/../src/assets/languages" -name "zh*" | wc -l)
  en=$(find "$SRC_DIR/../src/assets/languages" -name "en*" | wc -l)
  echo "  zh_cn 文件: $zh, en_us 文件: $en"
  if [ "$zh" -ne "$en" ]; then
    echo "  WARN: 中英文翻译文件数量不一致"
  fi
else
  echo "  (i18n 目录不存在，跳过)"
fi

echo ""
echo "==> DONE"
