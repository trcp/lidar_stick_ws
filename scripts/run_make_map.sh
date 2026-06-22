#!/bin/bash
# =============================================================================
# run_make_map.sh
#   Livox Mid360 ドライバ + GLIM をローカルで起動してマップを作成する。
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

# 一時的なバックグラウンドプロセスのトラップを設定
LIVOX_PID=""
cleanup() {
    echo "[run_make_map] 終了処理を実行中..."
    if [ -n "$LIVOX_PID" ]; then
        kill "$LIVOX_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# 1) Livox Mid360 ドライバをバックグラウンド起動 (RVizはここでは起動しない)
echo "[run_make_map] Livox Mid360 ドライバを起動しています..."
ros2 launch lidar_localization_ros2 livox_mid360.launch.py use_rviz:=false &
LIVOX_PID=$!

# ドライバが起動するまで少し待つ
sleep 3

# 2) GLIM SLAM ノードをフォアグラウンド起動 (Ctrl-C で終了)
echo "[run_make_map] GLIM SLAM を起動しています..."
ros2 run glim_ros glim_rosnode --ros-args -p config_path:=$PWD/config_glim
