import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch.conditions import IfCondition

def generate_launch_description():
    # デフォルトの設定ファイルパスをワークスペースの config/MID360_config.json に設定
    # 実行時のカレントディレクトリからの絶対パスに変換します
    default_config = os.path.abspath('config/MID360_config.json')

    user_config_path_arg = DeclareLaunchArgument(
        'user_config_path',
        default_value=default_config,
        description='Path to the user config json file'
    )

    use_rviz_arg = DeclareLaunchArgument(
        'use_rviz',
        default_value='true',
        description='Whether to start RViz2'
    )

    livox_ros2_params = [
        {"xfer_format": 0},
        {"multi_topic": 0},
        {"data_src": 0},
        {"publish_freq": 10.0},
        {"output_data_type": 0},
        {"frame_id": 'livox_frame'},
        {"lvx_file_path": '/home/livox/livox_test.lvx'},
        {"user_config_path": LaunchConfiguration('user_config_path')},
        {"cmdline_input_bd_code": 'livox0000000001'}
    ]

    livox_driver = Node(
        package='livox_ros_driver2',
        executable='livox_ros_driver2_node',
        name='livox_lidar_publisher',
        output='screen',
        parameters=livox_ros2_params
    )

    # RViz2 の設定ファイルパス（livox_ros_driver2 パッケージの share ディレクトリから取得）
    rviz_config_path = os.path.join(
        get_package_share_directory('livox_ros_driver2'),
        'config',
        'display_point_cloud_ROS2.rviz'
    )

    livox_rviz = Node(
        package='rviz2',
        executable='rviz2',
        output='screen',
        arguments=['--display-config', rviz_config_path],
        condition=IfCondition(LaunchConfiguration('use_rviz'))
    )

    return LaunchDescription([
        user_config_path_arg,
        use_rviz_arg,
        livox_driver,
        livox_rviz
    ])
