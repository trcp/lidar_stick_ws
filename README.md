# lidar_stick_ws

## 前提条件
- [Pixi](https://pixi.sh) がインストールされていること
- CUDA ツールキット（GLIM の GPU 処理に必要）

## 使用方法

### ワークスペースの初期セットアップ
以下のコマンドで、外部リポジトリの取得・パッチ適用、依存ライブラリのビルド、および ROS 2 ワークスペースのコンパイルまでの**すべての環境構築が完了**します。
```bash
pixi run setup
```

---

## 開発用個別コマンド
日常の開発ワークフローでは、必要に応じて以下のコマンドを個別に実行できます。

* **外部リポジトリの同期とパッチ適用**:
  ```bash
  pixi run clone-deps
  ```
* **外部 C++ 依存関係のビルド**:
  ```bash
  pixi run build-deps
  ```
* **ROS 2 ワークスペースのビルド**:
  ```bash
  pixi run build
  ```

---

## 実行・可視化

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
