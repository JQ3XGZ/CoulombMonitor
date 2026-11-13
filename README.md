# CoulombMonitor

macOSのメニューバーにバッテリー残量、リアルタイム電力（W）、電圧、電流などを常駐表示する軽量なシステムモニターユーティリティです。

---

## 主な機能

- **メニューバー常駐表示**:
  - バッテリー残量（%）および瞬時電力（W）のリアルタイム表示
  - 外部電源接続（給電中）、充電中、バッテリー駆動（残量連動）の3状態をアイコンで自動出し分け
  - 小数点以下の表示桁数設定（0〜2桁）
- **選べるアイコンテーマ**:
  - **macOS 標準 (SF Symbols)**: Apple標準のネイティブアイコン
  - **絵文字 (Emoji)**: ⚡️ 🔌 🔋 🪫 によるフルカラー絵文字表示
  - **Solar (Bold / Outline / Broken Line)**: モダンで洗練されたベクターアイコンセット（充電アイコンやバッテリー形状のサブカスタマイズ対応）
  - **Iconcino**: フラットでシンプルなアウトラインアイコン
  - **Generica (Tiny)**: コンパクトなドット・タイニーデザイン
- **詳細ポップオーバー表示**:
  - **外部電源**: 供給電力、入力電圧、入力電流、アダプタ定格（※未接続時は自動的に非表示）
  - **バッテリー**: 充放電電力、セル電圧、充放電電流、健全度（%）、充放電サイクル数、温度
  - **システム消費電力**: Mac本体が現在消費している合計電力
- **自動起動**:
  - ログイン時自動起動のON/OFF切り替え
- **軽量・クリーン設計**:
  - Dockアイコン非表示（`LSUIElement = YES`）のメニューバー専従アプリ
  - SwiftUI + `@Observable` による効率的な状態管理

---

## 動作要件

- macOS 26.0 以降（Apple Silicon / Intel Mac 対応）
- Xcode 26.0 以降

> [!NOTE]
> 本アプリは IOKit（`AppleSmartBattery` レジストリ）から瞬時電流・電圧・電力を直接読み取るため、**App Sandbox を無効化 (`ENABLE_APP_SANDBOX = NO`)** しています。

---

## インストール・実行方法

### 方法1: リリース済み DMG からインストール（推奨）

1. [Releases](https://github.com/JQ3XGZ/CoulombMonitor/releases) ページから最新の `CoulombMonitor-vX.X.X.dmg` をダウンロードします。
2. DMG をマウントし、`CoulombMonitor.app` を `Applications` フォルダへドラッグ＆ドロップします。

> [!TIP]
> **初回起動時に「マルウェアが含まれていないことを検証できませんでした」等の警告が出る場合**  
> 本アプリは個人開発のオープンソースソフトウェアであり、Apple の有料開発者証明書による公証（Notarization）を行っていないため、macOS の Gatekeeper により初回起動時に警告ダイアログが表示されます。  
> 以下のいずれかの方法で一度だけ起動を許可してください：
> 
> **方法A: 「システム設定」から許可する（GUI・推奨）**
> 1. 警告ダイアログで **「完了」** をクリックして閉じます。
> 2. macOSの **「システム設定」>「プライバシーとセキュリティ」** を開きます。
> 3. 画面下部の「セキュリティ」項目にある『“CoulombMonitor.app” は開発元を確認できないため、使用がブロックされました』の横の **「このまま開く」** をクリックします。
> 4. パスワードまたは Touch ID で認証すると、アプリが正常に起動します。
> 
> **方法B: ターミナルで隔離属性を解除する（CLI）**
> ```bash
> xattr -cr /Applications/CoulombMonitor.app
> ```
> ※ 一度許可すれば、次回以降は通常通りダブルクリックで直接起動できます。

---

### 方法2: ソースコードからビルド・実行

#### 1. リポジトリのクローン

```bash
git clone https://github.com/JQ3XGZ/CoulombMonitor.git
cd CoulombMonitor
```

#### 2-A. Xcodeから直接実行（開発・動作確認）

1. Xcode で `CoulombMonitor.xcodeproj` を開きます。
2. `Product` > `Run`（または `Cmd + R`）を実行します。
3. メニューバーにアイコンとバッテリー情報が表示されます。

#### 2-B. ローカルでビルドしてインストール（通常利用・常駐利用）

常駐アプリとして日常的に使用する場合や、「ログイン時自動起動」機能を利用する場合は、Releaseビルドを作成して `/Applications`（アプリケーションフォルダ）にインストールすることを推奨します。

##### 手順A: Xcode（GUI）でビルド＆配置
1. Xcode で `CoulombMonitor.xcodeproj` を開きます。
2. メニューの `Product` > `Archive` を実行します。
3. アーカイブ完了後、**Organizer** ウィンドウが表示されるので、対象のアーカイブを選択して **Distribute App** をクリックします。
4. 配布オプションで **Custom** > **Copy App** を選択し、任意の場所（デスクトップなど）に書き出します。
5. 書き出された `CoulombMonitor.app` を `/Applications`（アプリケーションフォルダ）へ移動します。
6. `/Applications/CoulombMonitor.app` をダブルクリックして起動します。

##### 手順B: ターミナル（xcodebuild）で一括ビルド＆インストール
ターミナルからReleaseビルドを行って、直接アプリケーションフォルダにコピーすることも可能です：

```bash
# Releaseビルドを実行
xcodebuild -project CoulombMonitor.xcodeproj -scheme CoulombMonitor -configuration Release -derivedDataPath ./build

# アプリケーションフォルダにコピー（既存のものがある場合は上書き）
cp -R ./build/Build/Products/Release/CoulombMonitor.app /Applications/

# アプリを起動
open /Applications/CoulombMonitor.app

# ビルド成果物のクリーンアップ（任意）
rm -rf ./build
```

---

## アーキテクチャ

- **`BatteryMonitor.swift`**: `IOKit` / `IOPowerSources` からハードウェアデータを定期取得（バックグラウンド Task + `@Observable`）。
- **`BatteryInfo.swift`**: 外部電源、バッテリーセル、システム消費電力のメトリクスモデル。
- **`LaunchAtLoginService.swift`**: ServiceManagement フレームワークによるモダンな自動起動制御。
- **`AppSettings.swift`**: 表示設定・アイコンテーマ選択の永続化（`UserDefaults`）。
- **`MenuBarTitleView.swift` & `BatteryDetailView.swift`**: SwiftUI によるメニューバーラベルと詳細ポップオーバー。

---

## 謝辞・アイコン素材ライセンス (Attribution)

本アプリでは、以下のオープンライセンスによる素晴らしいアイコン素材を使用させていただいています：

- **Solar Bold Icons**
  - Author: 480 Design
  - Source: [SVG Repo - Solar Bold Icons](https://www.svgrepo.com/collection/solar-bold-icons/)
  - License: [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)
- **Solar Outline Icons**
  - Author: 480 Design
  - Source: [SVG Repo - Solar Outline Icons](https://www.svgrepo.com/collection/solar-outline-icons/)
  - License: [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)
- **Solar Broken Line Icons**
  - Author: 480 Design
  - Source: [SVG Repo - Solar Broken Line Icons](https://www.svgrepo.com/collection/solar-broken-line-icons/)
  - License: [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)
- **Generica Tiny Interface Icons**
  - Author: Generica
  - Source: [SVG Repo - Generica Tiny Interface Icons](https://www.svgrepo.com/collection/generica-tiny-interface-icons/)
  - License: [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)
- **Iconcino Interface Icons**
  - Source: [SVG Repo - Iconcino Interface Icons](https://www.svgrepo.com/collection/iconcino-interface-icons/)
  - License: Public Domain (CC0 / PD)

---

## ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。
