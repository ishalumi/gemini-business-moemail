#!/bin/bash
# Gemini Business API 启动脚本
# 启动 Xvfb 虚拟显示，然后启动应用

set -Eeuo pipefail

DISPLAY="${DISPLAY:-:99}"
XVFB_WHD="${XVFB_WHD:-1920x1080x24}"

echo "启动 Xvfb 虚拟显示..."
# 禁用 TCP 监听，提高安全性
Xvfb "$DISPLAY" -screen 0 "$XVFB_WHD" -nolisten tcp -noreset &
XVFB_PID=$!

export DISPLAY
display_num="${DISPLAY#:}"
x_sock="/tmp/.X11-unix/X${display_num}"

# 清理函数：确保退出时正确终止子进程
cleanup() {
  local code=$?
  trap - EXIT
  if [[ -n "${APP_PID:-}" ]]; then
    kill -TERM "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
  kill -TERM "$XVFB_PID" 2>/dev/null || true
  wait "$XVFB_PID" 2>/dev/null || true
  exit "$code"
}
trap cleanup EXIT

# 等待 Xvfb 就绪（检测 X11 socket 文件）
echo "等待 Xvfb 就绪..."
for i in {1..50}; do
  [[ -S "$x_sock" ]] && break
  if ! kill -0 "$XVFB_PID" 2>/dev/null; then
    echo "Xvfb 启动失败"
    exit 1
  fi
  sleep 0.1
done
if [[ ! -S "$x_sock" ]]; then
  echo "Xvfb 未就绪（未创建 $x_sock）"
  exit 1
fi

echo "Xvfb 已启动 (DISPLAY=$DISPLAY)"
echo "启动应用..."

# 启动应用
uv run python -u main.py &
APP_PID=$!

# 信号处理
term_handler() {
  kill -TERM "$APP_PID" 2>/dev/null || true
}
trap term_handler TERM INT

set +e
wait "$APP_PID"
APP_STATUS=$?
set -e
exit "$APP_STATUS"
