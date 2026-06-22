#!/bin/bash
set -e

# Make sure we are in pixi environment
if [ -z "$CONDA_PREFIX" ]; then
    echo "Error: This script must be run within a pixi environment (e.g. 'pixi run build')"
    exit 1
fi

# Dynamically resolve project root directory (one level up from scripts/)
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

echo "=== Building ROS 2 Workspace ==="
colcon build --symlink-install --cmake-args \
  -DROS_EDITION=ROS2 \
  -DDISTRO_ROS=humble \
  -DCMAKE_USE_RESPONSE_FILE_FOR_INCLUDES=ON \
  -DCMAKE_USE_RESPONSE_FILE_FOR_OBJECTS=ON \
  -DPython_EXECUTABLE="$CONDA_PREFIX/bin/python" \
  -DCMAKE_CXX_STANDARD=17 \
  -DCMAKE_CXX_FLAGS="-include cstdint"
