#!/bin/bash
set -e

# Make sure we are in pixi environment
if [ -z "$CONDA_PREFIX" ]; then
    echo "Error: This script must be run within a pixi environment (e.g. 'pixi run build')"
    exit 1
fi

# Dynamically resolve project root directory (one level up from scripts/)
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

# Determine if CUDA should be used (Auto-detect via nvcc availability, can be overridden by USE_CUDA)
if [ -n "$USE_CUDA" ]; then
    if [ "$USE_CUDA" = "ON" ] || [ "$USE_CUDA" = "1" ] || [ "$USE_CUDA" = "true" ]; then
        BUILD_WITH_CUDA=ON
    else
        BUILD_WITH_CUDA=OFF
    fi
else
    if command -v nvcc &> /dev/null; then
        echo "CUDA compiler (nvcc) found. Enabling CUDA support."
        BUILD_WITH_CUDA=ON
    else
        echo "CUDA compiler (nvcc) NOT found. Disabling CUDA support."
        BUILD_WITH_CUDA=OFF
    fi
fi

echo "=== Building ROS 2 Workspace ==="
colcon build --symlink-install --cmake-args \
  -DROS_EDITION=ROS2 \
  -DDISTRO_ROS=humble \
  -DCMAKE_USE_RESPONSE_FILE_FOR_INCLUDES=ON \
  -DCMAKE_USE_RESPONSE_FILE_FOR_OBJECTS=ON \
  -DPython_EXECUTABLE="$CONDA_PREFIX/bin/python" \
  -DBUILD_WITH_CUDA="$BUILD_WITH_CUDA" \
  -DCMAKE_CXX_STANDARD=17 \
  -DCMAKE_CXX_FLAGS="-include cstdint"
