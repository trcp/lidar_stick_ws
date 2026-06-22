#!/bin/bash
set -e

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

mkdir -p src
cd src

# 1. Livox-SDK2
if [ ! -d "Livox-SDK2" ]; then
    echo "Cloning Livox-SDK2..."
    git clone https://github.com/Livox-SDK/Livox-SDK2.git
    touch Livox-SDK2/COLCON_IGNORE
fi

# 2. livox_ros_driver2
if [ ! -d "livox_ros_driver2" ]; then
    echo "Cloning livox_ros_driver2..."
    git clone https://github.com/Livox-SDK/livox_ros_driver2.git
    cd livox_ros_driver2
    mv package_ROS2.xml package.xml
    cp -rf launch_ROS2 launch
    cd ..
fi

# 3. ndt_omp_ros2
if [ ! -d "ndt_omp_ros2" ]; then
    echo "Cloning ndt_omp_ros2..."
    git clone -b humble https://github.com/rsasaki0109/ndt_omp_ros2.git
fi

# 3.5. GTSAM
if [ ! -d "gtsam" ]; then
    echo "Cloning GTSAM..."
    git clone -b 4.3a0 https://github.com/borglab/gtsam.git
    touch gtsam/COLCON_IGNORE
fi

# 4. gtsam_points
if [ ! -d "gtsam_points" ]; then
    echo "Cloning gtsam_points..."
    git clone https://github.com/koide3/gtsam_points.git
    touch gtsam_points/COLCON_IGNORE
fi

# 5. iridescence
if [ ! -d "iridescence" ]; then
    echo "Cloning iridescence..."
    git clone https://github.com/koide3/iridescence.git
    touch iridescence/COLCON_IGNORE
fi
cd iridescence && git submodule update --init --recursive && cd ..

# 6. glim
if [ ! -d "glim" ]; then
    echo "Cloning glim..."
    git clone https://github.com/koide3/glim.git
    touch glim/COLCON_IGNORE
fi
cd glim && git submodule update --init --recursive && cd ..

# 7. glim_ros2
if [ ! -d "glim_ros2" ]; then
    echo "Cloning glim_ros2..."
    git clone https://github.com/koide3/glim_ros2.git
fi

echo "Workspace cloning completed!"
