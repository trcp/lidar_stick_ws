# =============================================================================
# lidar_stick_localization.launch.py
#   Livox MID360 + lidar_stick_map (PCD) でローカライゼーションのみを起動する
#   専用 launch。Nav2 は一切含まない。
#
#   起動例:
#     ros2 launch lidar_localization_ros2 lidar_stick_localization.launch.py
#     ros2 launch lidar_localization_ros2 lidar_stick_localization.launch.py \
#         map_path:=/root/colcon_ws/lidar_stick_map/lidar_stick_map.pcd \
#         cloud_topic:=/livox/lidar
#
#   前提: livox_ros_driver2 が PointCloud2 を /livox/lidar (frame_id=livox_frame)
#         に publish していること。
# =============================================================================
import os

import launch.actions
import launch.events

import launch_ros.actions
import launch_ros.events

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.conditions import IfCondition
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import LifecycleNode
from launch_ros.actions import Node

import lifecycle_msgs.msg

from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    localization_param_file = LaunchConfiguration(
        'localization_param_file',
        default=os.path.join(
            get_package_share_directory('lidar_localization_ros2'),
            'param',
            'lidar_stick_localization.yaml'))
    cloud_topic = LaunchConfiguration('cloud_topic', default='/livox/lidar')
    imu_topic = LaunchConfiguration('imu_topic', default='/livox/imu')
    twist_topic = LaunchConfiguration('twist_topic', default='/twist')
    # 既定はコンテナ内 (compose で lidar_stick_map をマウントしている) パス。
    map_path = LaunchConfiguration(
        'map_path',
        default='/root/colcon_ws/lidar_stick_map/lidar_stick_map.pcd')
    lidar_frame_id = LaunchConfiguration('lidar_frame_id', default='livox_frame')
    use_sim_time = LaunchConfiguration('use_sim_time', default='false')
    # 2D 占有格子地図 (nav2_map_server) の表示。
    use_map_server = LaunchConfiguration('use_map_server', default='true')
    map_yaml = LaunchConfiguration(
        'map_yaml',
        default='/root/colcon_ws/lidar_stick_map/map.yaml')

    # base_link -> livox_frame の静的 TF。ロボットへの LiDAR 取り付け位置・姿勢。
    #   z=1.3m, yaw=3.14, pitch=3.14 (rad)
    lidar_tf = Node(
        name='base_link_to_lidar_tf',
        package='tf2_ros',
        executable='static_transform_publisher',
        arguments=[
            '--x', '0.0',
            '--y', '0.0',
            '--z', '1.3',
            '--roll', '0.0',
            '--pitch', '3.14',
            '--yaw', '3.14',
            '--frame-id', 'base_link',
            '--child-frame-id', lidar_frame_id,
        ])

    lidar_localization = LifecycleNode(
        name='lidar_localization',
        namespace='',
        package='lidar_localization_ros2',
        executable='lidar_localization_node',
        parameters=[
            localization_param_file,
            {'use_sim_time': use_sim_time},
            # yaml の map_path を launch 引数で上書き。
            {'map_path': map_path},
        ],
        remappings=[
            ('/cloud', cloud_topic),
            ('/twist', twist_topic),
            ('/imu', imu_topic),
        ],
        output='screen')

    # --- 2D 占有格子地図 (/map, OccupancyGrid) ------------------------------
    # map_server は lifecycle ノードなので lifecycle_manager(autostart) で起動する。
    map_server = Node(
        package='nav2_map_server',
        executable='map_server',
        name='map_server',
        output='screen',
        parameters=[{
            'use_sim_time': use_sim_time,
            'yaml_filename': map_yaml,
            'frame_id': 'map',
            'topic_name': 'map',
        }],
        condition=IfCondition(use_map_server))

    map_server_lifecycle = Node(
        package='nav2_lifecycle_manager',
        executable='lifecycle_manager',
        name='lifecycle_manager_map_server',
        output='screen',
        parameters=[{
            'use_sim_time': use_sim_time,
            'autostart': True,
            'node_names': ['map_server'],
        }],
        condition=IfCondition(use_map_server))

    # --- Lifecycle 自動遷移: unconfigured -> inactive -> active -------------
    to_inactive = launch.actions.EmitEvent(
        event=launch_ros.events.lifecycle.ChangeState(
            lifecycle_node_matcher=launch.events.matches_action(lidar_localization),
            transition_id=lifecycle_msgs.msg.Transition.TRANSITION_CONFIGURE,
        )
    )

    from_unconfigured_to_inactive = launch.actions.RegisterEventHandler(
        launch_ros.event_handlers.OnStateTransition(
            target_lifecycle_node=lidar_localization,
            goal_state='unconfigured',
            entities=[
                launch.actions.LogInfo(msg="-- Unconfigured --"),
                launch.actions.EmitEvent(event=launch_ros.events.lifecycle.ChangeState(
                    lifecycle_node_matcher=launch.events.matches_action(lidar_localization),
                    transition_id=lifecycle_msgs.msg.Transition.TRANSITION_CONFIGURE,
                )),
            ],
        )
    )

    from_inactive_to_active = launch.actions.RegisterEventHandler(
        launch_ros.event_handlers.OnStateTransition(
            target_lifecycle_node=lidar_localization,
            start_state='configuring',
            goal_state='inactive',
            entities=[
                launch.actions.LogInfo(msg="-- Inactive --"),
                launch.actions.EmitEvent(event=launch_ros.events.lifecycle.ChangeState(
                    lifecycle_node_matcher=launch.events.matches_action(lidar_localization),
                    transition_id=lifecycle_msgs.msg.Transition.TRANSITION_ACTIVATE,
                )),
            ],
        )
    )

    return LaunchDescription([
        DeclareLaunchArgument('localization_param_file',
                              default_value=localization_param_file),
        DeclareLaunchArgument('cloud_topic', default_value='/livox/lidar'),
        DeclareLaunchArgument('imu_topic', default_value='/livox/imu'),
        DeclareLaunchArgument('twist_topic', default_value='/twist'),
        DeclareLaunchArgument('map_path', default_value=map_path),
        DeclareLaunchArgument('lidar_frame_id', default_value='livox_frame'),
        DeclareLaunchArgument('use_sim_time', default_value='false'),
        DeclareLaunchArgument('use_map_server', default_value='true'),
        DeclareLaunchArgument('map_yaml', default_value=map_yaml),
        from_unconfigured_to_inactive,
        from_inactive_to_active,
        lidar_localization,
        lidar_tf,
        map_server,
        map_server_lifecycle,
        to_inactive,
    ])
