#!/bin/bash
# =============================================================================
# run_localization.sh
#   Livox Mid360 ドライバ + 可視化 (RViz2) + 自己位置推定をローカルで起動する。
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")"

# 一時的なバックグラウンドプロセスのトラップを設定
LIVOX_PID=""
RVIZ_PID=""
cleanup() {
    echo "[run_localization] 終了処理を実行中..."
    if [ -n "$LIVOX_PID" ]; then
        kill "$LIVOX_PID" 2>/dev/null || true
    fi
    if [ -n "$RVIZ_PID" ]; then
        kill "$RVIZ_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# 1) Livox Mid360 ドライバをバックグラウンド起動 (RVizはここでは起動しない)
echo "[run_localization] Livox Mid360 ドライバを起動しています..."
ros2 launch lidar_localization_ros2 livox_mid360.launch.py use_rviz:=false &
LIVOX_PID=$!

# 2) RViz2 をバックグラウンド起動
echo "[run_localization] RViz2 を起動しています..."
rviz2 -d src/lidar_localization_ros2/lidar_stick.rviz &
RVIZ_PID=$!

# ドライバが起動するまで少し待つ
sleep 3

# 3) 自己位置推定をフォアグラウンド起動 (Ctrl-C で終了)
echo "[run_localization] 自己位置推定 (Localization) を起動しています..."
ros2 launch lidar_localization_ros2 lidar_stick_localization.launch.py
