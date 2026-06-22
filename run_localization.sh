#!/bin/bash
# =============================================================================
# run_localization.sh
#   Livox Mid360 ドライバ + lidar_localization_ros2 を 1 コンテナで起動して
#   自己位置推定 (localization) を実行する。
#
#   使い方:
#     ./run_localization.sh gpu    # GPU 版 (compose.yaml) で起動
#     ./run_localization.sh cpu    # CPU 版 (compose.cpu.yaml) で起動
#   ※ 引数は cpu / gpu のいずれか必須。それ以外はエラー終了する。
#
#   仕組み:
#     docker compose run で起動したコンテナ内で
#       1) livox_ros_driver2 を background 起動 (PointCloud2 を出す)
#       2) rviz2 を background 起動 (ホストの ./default.rviz を -d で読む)
#       3) lidar_stick_localization.launch.py を foreground 起動 (Ctrl-C で終了)
#     終了時に livox ドライバ / rviz2 も合わせて停止する。
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")"

# ---- compose ファイルの選択 (cpu / gpu) -------------------------------------
usage() {
    echo "usage: $0 {cpu|gpu}" >&2
    exit 1
}

case "${1:-}" in
    gpu) COMPOSE_FILE="compose.yaml" ;;
    cpu) COMPOSE_FILE="compose.cpu.yaml" ;;
    *)   usage ;;
esac

# ---- GUI (RViz) 表示の許可 --------------------------------------------------
# DISPLAY が無いヘッドレス環境では何もしない
if [[ -n "${DISPLAY:-}" ]]; then
    xhost +local:root >/dev/null 2>&1 || true
fi

# ---- コンテナ内で実行するコマンド -------------------------------------------
read -r -d '' CONTAINER_CMD <<'EOS' || true
set -e
# 1) Livox Mid360 ドライバを background 起動 (PointCloud2 出力, rviz は同梱しない)
ros2 launch livox_ros_driver2 rviz_MID360_launch.py &
LIVOX_PID=$!

# 2) rviz2 を background 起動 (ホストの ./default.rviz を compose でマウント済み)
rviz2 -d /root/default.rviz &
RVIZ_PID=$!

# ドライバが点群を出し始めるまで少し待つ
sleep 3

# ドライバ / rviz 終了時に localization も道連れにするためのトラップ
trap 'kill $LIVOX_PID $RVIZ_PID 2>/dev/null || true' EXIT INT TERM

# 3) lidar_localization_ros2 を foreground 起動 (Ctrl-C で終了)
#    パッケージはイメージにビルド済み (entrypoint で install/setup.bash を source)
ros2 launch lidar_localization_ros2 lidar_stick_localization.launch.py
EOS

echo "[run_localization] compose file : ${COMPOSE_FILE}"
echo "[run_localization] Ctrl-C で localization と Livox ドライバを停止します"

exec docker compose -f "${COMPOSE_FILE}" run --rm livox \
    bash -c "${CONTAINER_CMD}"
