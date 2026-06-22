# lidar_stick_ws

## 前提条件

- [Pixi](https://pixi.sh) がインストールされていること
- CUDA ツールキット（GLIM の GPU 処理に必要）

## ワークスペースの初期セットアップ

以下のコマンドで、外部リポジトリの取得・パッチ適用、依存ライブラリのビルド、および ROS 2 ワークスペースのコンパイルまでの**すべての環境構築が完了**します。
```bash
pixi run setup
```

## 開発用個別コマンド

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

## 実行・可視化

### 個別ノードの起動

* **Livox Mid360 ドライバの起動**:
  ```bash
  pixi run launch-driver
  ```
* **GLIM SLAM ノードの起動**:
  ```bash
  pixi run launch-glim
  ```
* **自己位置推定 (Localization) ノードの起動**:
  ```bash
  pixi run launch-localization
  ```
* **RViz2 による可視化**:
  ```bash
  pixi run rviz
  ```

### オールインワン実行（推奨）

ドライバや可視化、SLAM/Localizationなどを一括で起動する便利なタスクが用意されています。

* **マッピング（地図作成）の実行**:
  LivoxドライバとGLIM SLAMノードをまとめて起動します。
  ```bash
  pixi run run-mapping
  ```
* **自己位置推定（Localization）の実行**:
  Livoxドライバ、RViz2、自己位置推定ノードをまとめて起動します。
  ```bash
  pixi run run-localization
  ```
