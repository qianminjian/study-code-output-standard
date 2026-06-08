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
grep -rnE "(secret|password|token)\\s*=\\s*[\"'][^\"']{8,}[\"']" \
  "$SRC_DIR" 2>/dev/null \
  | grep -v "test" \
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
grep -rn "actuator" "$SRC_DIR" 2>/dev/null | head -5 || echo "  (no actuator)"

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
