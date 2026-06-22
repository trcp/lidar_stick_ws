#!/bin/bash
# =============================================================================
# run_make_map.sh
#   Livox Mid360 ドライバ + GLIM を 1 コンテナで起動してマップを作成する。
#
#   使い方:
#     ./run_make_map.sh gpu        # GPU 版 (compose.yaml) で起動
#     ./run_make_map.sh cpu        # CPU 版 (compose.cpu.yaml) で起動
#   ※ 引数は cpu / gpu のいずれか必須。それ以外はエラー終了する。
#
#   仕組み:
#     docker compose run で起動したコンテナ内で
#       1) livox_ros_driver2 を background 起動 (PointCloud2 を出す msg_MID360)
#       2) glim_rosnode を foreground 起動 (Ctrl-C で終了)
#     終了時に livox ドライバも合わせて停止する。
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

# ---- GUI (RViz / GLIM viewer) 表示の許可 ------------------------------------
# DISPLAY が無いヘッドレス環境では何もしない
if [[ -n "${DISPLAY:-}" ]]; then
    xhost +local:root >/dev/null 2>&1 || true
fi

# ---- コンテナ内で実行するコマンド -------------------------------------------
# config_glim はホストの ./config_glim を /root/config_glim にマウント済み。
read -r -d '' CONTAINER_CMD <<'EOS' || true
set -e
# 1) Livox Mid360 ドライバを background 起動 (PointCloud2 出力)
ros2 launch livox_ros_driver2 rviz_MID360_launch.py &
LIVOX_PID=$!

# ドライバが点群を出し始めるまで少し待つ
sleep 3

# ドライバ終了時に GLIM も道連れにするためのトラップ
trap 'kill $LIVOX_PID 2>/dev/null || true' EXIT INT TERM

# 2) GLIM を foreground 起動 (Ctrl-C で終了)
ros2 run glim_ros glim_rosnode \
    --ros-args -p config_path:=/root/config_glim
EOS

echo "[run_make_map] compose file : ${COMPOSE_FILE}"
echo "[run_make_map] Ctrl-C で GLIM と Livox ドライバを停止します"

exec docker compose -f "${COMPOSE_FILE}" run --rm livox \
    bash -c "${CONTAINER_CMD}"
