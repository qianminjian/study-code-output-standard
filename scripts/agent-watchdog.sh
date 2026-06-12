#!/usr/bin/env bash
# agent-watchdog.sh — agent stall 自动检测与恢复
# 用法：bash scripts/agent-watchdog.sh <agent-output-file> [agent-pid]
#
# 每 60s 检测 agent output 文件大小变化
# 300s 无变化 → stall detected → kill agent PID + 输出 stall event
#
# 环境变量：
#   WATCHDOG_INTERVAL=60     检测间隔（秒）
#   WATCHDOG_THRESHOLD=300   失速阈值（秒）

set -e

AGENT_OUTPUT_FILE="$1"
AGENT_PID="${2:-}"

if [ -z "$AGENT_OUTPUT_FILE" ]; then
  echo "用法：bash scripts/agent-watchdog.sh <agent-output-file> [agent-pid]"
  echo ""
  echo "  检测 agent output 文件大小变化，300s 无变化 → stall 告警 + kill agent"
  echo "  若不提供 agent-pid，watchdog 自动通过 lsof/fuser 查找持有文件的进程"
  exit 1
fi

CHECK_INTERVAL="${WATCHDOG_INTERVAL:-60}"
STALL_THRESHOLD="${WATCHDOG_THRESHOLD:-300}"

# --- 平台适配 ---
detect_platform() {
  case "$(uname -s)" in
    Darwin)  echo "macos" ;;
    Linux)   echo "linux"  ;;
    *)       echo "unknown";;
  esac
}
PLATFORM=$(detect_platform)

get_file_size() {
  local f="$1"
  if [ "$PLATFORM" = "macos" ]; then
    stat -f%z "$f" 2>/dev/null || echo 0
  else
    stat -c%s "$f" 2>/dev/null || echo 0
  fi
}

get_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# --- PID 发现 ---
find_writer_pid() {
  local f="$1"
  # macOS: lsof +f -- <file> 返回持有该文件的进程
  if [ "$PLATFORM" = "macos" ]; then
    lsof +f -- "$f" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | head -1
  else
    # Linux: fuser 找持有文件句柄的进程
    fuser "$f" 2>/dev/null | grep -oE '[0-9]+' | head -1
  fi
}

# --- 等待输出文件出现 ---
if [ ! -f "$AGENT_OUTPUT_FILE" ]; then
  echo "[$(get_timestamp)] agent-watchdog: 输出文件 $AGENT_OUTPUT_FILE 不存在，等待创建..."
  waited=0
  while [ ! -f "$AGENT_OUTPUT_FILE" ]; do
    sleep 2
    waited=$((waited + 2))
    if [ "$waited" -ge 120 ]; then
      echo "[$(get_timestamp)] agent-watchdog: 超时（120s），输出文件未创建，退出"
      exit 1
    fi
  done
  echo "[$(get_timestamp)] agent-watchdog: 输出文件已创建，开始监控"
fi

# --- 输出 stall event ---
emit_stall_event() {
  local duration="$1"
  local file_size="$2"
  local killed_pid="$3"
  local action="$4"

  cat <<STALL_EVENT
{
  "event": "agent_stall",
  "timestamp": "$(get_timestamp)",
  "output_file": "$AGENT_OUTPUT_FILE",
  "stall_duration_s": $duration,
  "file_size_bytes": $file_size,
  "pid_killed": $killed_pid,
  "action": "$action",
  "watchdog": {
    "interval_s": $CHECK_INTERVAL,
    "threshold_s": $STALL_THRESHOLD,
    "platform": "$PLATFORM"
  }
}
STALL_EVENT
}

# --- Kill agent ---
kill_agent() {
  local pid="$1"
  if [ -z "$pid" ]; then
    echo "[$(get_timestamp)] agent-watchdog: 无法获取 agent PID，不执行 kill"
    return 1
  fi

  # 验证 PID 是否存在
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "[$(get_timestamp)] agent-watchdog: PID $pid 已不存在"
    return 0
  fi

  echo "[$(get_timestamp)] agent-watchdog: 发送 SIGTERM → PID $pid"
  kill -TERM "$pid" 2>/dev/null || true

  # 等待 5 秒 graceful shutdown
  local waited=0
  while kill -0 "$pid" 2>/dev/null && [ "$waited" -lt 5 ]; do
    sleep 1
    waited=$((waited + 1))
  done

  # 若仍未退出，SIGKILL
  if kill -0 "$pid" 2>/dev/null; then
    echo "[$(get_timestamp)] agent-watchdog: SIGTERM 未生效，发送 SIGKILL → PID $pid"
    kill -KILL "$pid" 2>/dev/null || true
  fi

  echo "[$(get_timestamp)] agent-watchdog: PID $pid 已终止"
  return 0
}

# ==================== 主监控循环 ====================

echo "[$(get_timestamp)] agent-watchdog: 启动监控"
echo "  输出文件: $AGENT_OUTPUT_FILE"
echo "  检测间隔: ${CHECK_INTERVAL}s"
echo "  失速阈值: ${STALL_THRESHOLD}s"
echo "  Agent PID: ${AGENT_PID:-自动检测}"
echo ""

last_size=$(get_file_size "$AGENT_OUTPUT_FILE")
stall_count=0
last_change_time=$(date +%s)

while true; do
  sleep "$CHECK_INTERVAL"

  # 输出文件可能被 agent 删除/重命名
  if [ ! -f "$AGENT_OUTPUT_FILE" ]; then
    echo "[$(get_timestamp)] agent-watchdog: 输出文件消失（agent 可能已退出），停止监控"
    exit 0
  fi

  current_size=$(get_file_size "$AGENT_OUTPUT_FILE")

  if [ "$current_size" -ne "$last_size" ]; then
    # 文件有变化 → 重置失速计数
    stall_count=0
    last_size=$current_size
    last_change_time=$(date +%s)
  else
    stall_count=$((stall_count + 1))
    stall_duration=$((stall_count * CHECK_INTERVAL))

    if [ "$stall_duration" -ge "$STALL_THRESHOLD" ]; then
      # === STALL DETECTED ===
      echo ""
      echo "========================================="
      echo "  ⚠ AGENT STALL DETECTED"
      echo "========================================="
      echo "  失速时长: ${stall_duration}s"
      echo "  文件大小: ${current_size} bytes"
      echo "  最后变化: $(date -r "$last_change_time" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")"
      echo "  输出文件: $AGENT_OUTPUT_FILE"
      echo ""

      # 确定要 kill 的 PID
      TARGET_PID="${AGENT_PID}"
      if [ -z "$TARGET_PID" ]; then
        TARGET_PID=$(find_writer_pid "$AGENT_OUTPUT_FILE")
      fi

      # 输出 stall event JSON
      echo "--- stall event ---"
      emit_stall_event "$stall_duration" "$current_size" "${TARGET_PID:-0}" "killed"

      # Kill agent
      if [ -n "$TARGET_PID" ]; then
        kill_agent "$TARGET_PID"
      else
        echo "[$(get_timestamp)] agent-watchdog: 无法确定 agent PID，不 kill"
      fi

      echo ""
      echo "agent-watchdog: 退出（stall 已处理）"
      exit 0
    fi
  fi
done
