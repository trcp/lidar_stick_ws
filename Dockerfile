# =============================================================================
# Livox Mid360 用 Dockerfile  (ROS 2 Humble + CUDA / Ubuntu 22.04)
#   - Livox-SDK2        : Mid360 を扱う公式 SDK
#   - livox_ros_driver2 : Mid360 の ROS 2 ドライバ
# =============================================================================
FROM koide3/glim_ros2:humble_cuda12.2

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# NVIDIA Container Toolkit で GPU を利用可能にする
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all

# -----------------------------------------------------------------------------
# 基本ツール
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        gnupg2 \
        lsb-release \
        ca-certificates \
        software-properties-common \
        build-essential \
        cmake \
        git \
        sudo \
        locales \
        wget \
	tmux \
	vim \
	pcl-tools \
        ros-humble-rviz2 \
        ros-humble-rviz-common \
        ros-humble-nav2-map-server \
        ros-humble-nav2-lifecycle-manager \
        ros-humble-rosbridge-server \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Livox-SDK2 のビルド & インストール
# -----------------------------------------------------------------------------
RUN git clone https://github.com/Livox-SDK/Livox-SDK2.git /opt/Livox-SDK2 \
    && cd /opt/Livox-SDK2 \
    && mkdir build && cd build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release \
    && make -j"$(nproc)" \
    && make install \
    && ldconfig

# -----------------------------------------------------------------------------
# livox_ros_driver2 を colcon ワークスペースにビルド
# -----------------------------------------------------------------------------
ENV ROS_WS=/root/colcon_ws
RUN mkdir -p ${ROS_WS}/src \
    && git clone https://github.com/Livox-SDK/livox_ros_driver2.git \
    ${ROS_WS}/src/livox_ros_driver2 \
    && cd ${ROS_WS}/src/livox_ros_driver2 \
    && mv package_ROS2.xml package.xml \
    && cp -rf launch_ROS2 launch


# -----------------------------------------------------------------------------
# lidar_localization_ros2 (rsasaki0109) を colcon_ws に追加
#   - ndt_omp_ros2 (humble) : 必須の NDT 実装
#   - small_gicp (koide3)    : GICP/VGICP バックエンド用 (任意)
# -----------------------------------------------------------------------------
# small_gicp を先にシステムへインストール (GICP バックエンドを使う場合)
# RUN git clone https://github.com/koide3/small_gicp.git /opt/small_gicp \
#     && cd /opt/small_gicp \
#     && cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_WITH_PCL=ON \
#     && cmake --build build -j"$(nproc)" \
#     && cmake --install build \
#     && ldconfig

# 依存リポジトリを取得
RUN git clone -b humble https://github.com/rsasaki0109/ndt_omp_ros2.git \
        ${ROS_WS}/src/ndt_omp_ros2 \
    && git clone https://github.com/rsasaki0109/lidar_localization_ros2.git \
        ${ROS_WS}/src/lidar_localization_ros2

# rosdep で不足依存 (pcl_ros 等) を解決する
RUN /bin/bash -c "source /opt/ros/humble/setup.bash \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python3-rosdep python3-colcon-common-extensions \
    && (rosdep init || true) \
    && rosdep update \
    && rosdep install --from-paths ${ROS_WS}/src --ignore-src -r -y \
    && rm -rf /var/lib/apt/lists/*"

# ホストの lidar_stick 用の param / launch を clone 済みパッケージへ上書きコピーする
COPY lidar_stick_localization.yaml \
        ${ROS_WS}/src/lidar_localization_ros2/param/lidar_stick_localization.yaml
COPY lidar_stick_localization.launch.py \
        ${ROS_WS}/src/lidar_localization_ros2/launch/lidar_stick_localization.launch.py

# colcon build (livox は ROS2/Humble 用の cmake 引数が必要)
RUN /bin/bash -c "source /opt/ros/humble/setup.bash \
    && cd ${ROS_WS} \
    && colcon build --symlink-install \
        --cmake-args -DROS_EDITION=ROS2 -DDISTRO_ROS=humble --cmake-clean-cache"

# -----------------------------------------------------------------------------
# pointcloud_to_2dmap (koide3) : PCD から 2D 占有格子地図 (pgm/yaml) を生成
#   PCL 1.12 では boost::make_shared が使えずビルドエラーになるため、
#   pcl::make_shared へ置換してからビルドする。
#   CMakeLists に install ターゲットが無いので、生成バイナリを手動で配置する。
# -----------------------------------------------------------------------------
RUN git clone https://github.com/koide3/pointcloud_to_2dmap.git /opt/pointcloud_to_2dmap \
    && sed -i 's/boost::make_shared/pcl::make_shared/g' \
        /opt/pointcloud_to_2dmap/src/pointcloud_to_2dmap.cpp \
    && mkdir -p /opt/pointcloud_to_2dmap/build \
    && cd /opt/pointcloud_to_2dmap/build \
    && cmake .. \
    && make -j"$(nproc)" \
    && cp pointcloud_to_2dmap /usr/local/bin/

# -----------------------------------------------------------------------------
# entrypoint
# -----------------------------------------------------------------------------
COPY docker/ros_entrypoint.sh /ros_entrypoint.sh
RUN chmod +x /ros_entrypoint.sh

WORKDIR ${ROS_WS}
ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
