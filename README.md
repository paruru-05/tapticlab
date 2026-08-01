# HapticsLab

Taptic Engine をフルコントロールできる iOS アプリ（SwiftUI / iOS 17+）。

Xcode はローカルに必要ありません。コードをプッシュすると **GitHub Actions**（macOS ランナー）が署名なし IPA をビルドし、**Sideloadly**（Windows/macOS）でフリー Apple ID により iPhone にインストールできます。

## 機能

- **System** … `UINotificationFeedbackGenerator` / `UIImpactFeedbackGenerator`（強度調整付き）/ `UISelectionFeedbackGenerator`
- **Playground** … 2D パレットで intensity（強さ）/ sharpness（鋭さ）を指でリアルタイム操作（Transient / Continuous）
- **Editor** … イベントベースのパターン編集、プリセット、保存/読込、**AHAP(JSON) のエクスポート/インポート**
- **Advanced** … Engine の start/stop/状態監視、連続再生のライブ調整、再生速度・ループ、生 AHAP のペースト再生

## セットアップ（初回のみ）

1. このリポジトリを GitHub に作成してプッシュします。
   ```
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/<user>/<repo>.git
   git push -u origin main
   ```
2. GitHub のリポジトリ → **Actions** → 「Build IPA (Sideload / Free)」を手動実行します。
   - 任意で **bundle_id** を変更（例 `com.yourname.tapticlab`、ドット区切り必須）。
3. ビルド完了後、実行ページ下部の **Artifacts** から `HapticsLab-unsigned-*.ipa` をダウンロードします。

## インストール（Sideloadly / Windows・macOS）

1. https://sideloadly.io から Sideloadly をダウンロードし、iPhone を USB 接続します。
2. Sideloadly で IPA を選択し、フリーの **Apple ID / パスワード** を入力 → **Start**。
3. 初回のみ **設定 → 一般 → VPNとデバイス管理** で開発者プロファイルを信頼します。

## 注意点（フリー Apple ID）

- アプリは **7 日で失効** します。失効したら再び IPA を Sideloadly でインストールして更新してください。
- 同時にインストールできるアプリは約 3 個までです。
- ハプティクス（Taptic Engine）は **実機のみ** 動作します。シミュレータでは無効です。
- 初回ビルドは XcodeGen のダウンロードを含め約 10〜20 分かかります。

## 開発の流れ

1. コードを編集
2. `git push`
3. Actions でビルド（`push` でも `workflow_dispatch` でも可）
4. IPA をダウンロード → Sideloadly でインストール

## プロジェクト構成

- `project.yml` … XcodeGen 定義。`HapticsLab.xcodeproj` は CI で自動生成される（コミット不要）
- `HapticsLab/` … Swift ソース
  - `Haptics/HapticEngineManager.swift` … CHHapticEngine の一元管理（reset/stop 自動復帰、連続再生の動的パラメータ）
  - `Haptics/HapticPattern.swift` … パターンモデル（Codable）
  - `Haptics/AHAPCodec.swift` … AHAP(JSON) 変換
  - `Haptics/Presets.swift` … サンプルパターン
  - `Haptics/PatternStore.swift` … 保存済みパターン（UserDefaults）
- `.github/workflows/build-ipa.yml` … 署名なし IPA のビルドワークフロー
