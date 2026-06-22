#!/bin/bash
set -e

# Make sure we are in pixi environment
if [ -z "$CONDA_PREFIX" ]; then
    echo "Error: This script must be run within a pixi environment (e.g. 'pixi run build-deps')"
    exit 1
fi

# Dynamically resolve project root directory (one level up from scripts/)
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

echo "=== 1. Building Livox-SDK2 ==="
cd "$ROOT_DIR/src/Livox-SDK2"
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_CXX_FLAGS="-include cstdint"
make -j"$(nproc)"
make install

echo "=== 2. Building GTSAM ==="
cd "$ROOT_DIR/src/gtsam"
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
         -DGTSAM_BUILD_WITH_MARCH_NATIVE=OFF \
         -DGTSAM_BUILD_TESTS=OFF \
         -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF \
         -DGTSAM_WITH_TBB=OFF \
         -DGTSAM_BUILD_PYTHON=OFF \
         -DGTSAM_BUILD_UNSTABLE=ON \
         -DGTSAM_USE_SYSTEM_EIGEN=ON \
         -DGTSAM_USE_STD_SHARED_PTR=ON \
         -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
make install

echo "=== 3. Building gtsam_points ==="
cd "$ROOT_DIR/src/gtsam_points"
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
         -DBUILD_WITH_CUDA=ON \
         -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
make install

echo "=== 4. Building iridescence ==="
cd "$ROOT_DIR/src/iridescence"
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
make install

echo "=== 5. Building glim ==="
cd "$ROOT_DIR/src/glim"
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
         -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
         -DCMAKE_USE_RESPONSE_FILE_FOR_INCLUDES=ON \
         -DCMAKE_USE_RESPONSE_FILE_FOR_OBJECTS=ON \
         -DCMAKE_CXX_FLAGS="-include cstdint"
make -j"$(nproc)"
make install

echo "=== All external C++ dependencies built and installed successfully into $CONDA_PREFIX ==="
