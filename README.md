# lidar_stick_ws

Pixi を用いて構築された、Livox Mid360 および GLIM SLAM 用の ROS 2 Humble 開発環境です。

## 前提条件
- [Pixi](https://pixi.sh) がインストールされていること
- CUDA ツールキット（GLIM の GPU 処理に必要）

## 使用方法

### 1. ワークスペースのセットアップ
外部の依存リポジトリを自動クローンし、必要な互換性パッチを自動適用します。
```bash
pixi run setup
```

### 2. 外部 C++ 依存関係のビルド
GTSAM, gtsam_points, iridescence, GLIM などの外部依存ライブラリを Pixi 環境内へビルド・インストールします。
```bash
pixi run build-deps
```

### 3. ROS 2 ワークスペースのビルド
ROS 2 パッケージ（`ndt_omp_ros2`, `lidar_localization_ros2` など）をビルドします。
```bash
pixi run build
```

---

## 実行・可視化

### ROS 2 シェルの起動
ビルド済みの環境変数がアクティベートされた対話型シェルに入ります。
```bash
pixi run shell
```

### ドライバと SLIM の起動（別端末で実行）
* **Livox Mid360 ドライバの起動**:
  ```bash
  pixi run launch-driver
  ```
* **GLIM SLAM ノードの起動**:
  ```bash
  pixi run launch-glim
  ```
* **RViz2 による可視化**:
  ```bash
  pixi run rviz
  ```
