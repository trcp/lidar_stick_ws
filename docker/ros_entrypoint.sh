#!/bin/bash
# ROS 2 環境と livox_ros_driver2 のワークスペースを自動で source する
set -e

source /opt/ros/humble/setup.bash
source /root/ros2_ws/install/setup.bash

if [ -f "${ROS_WS}/install/setup.bash" ]; then
    source "${ROS_WS}/install/setup.bash"
fi

exec "$@"
