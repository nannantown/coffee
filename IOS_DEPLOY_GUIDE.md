# iOS デプロイガイド

## 1. 準備

### 必要なもの
- Apple Developer アカウント（年間 $99）
- Xcode（最新版推奨）
- 実機のiPhone（実機テスト用）

## 2. Bundle Identifier の変更

現在のBundle ID: `com.example.accountTemplate`

これを変更する必要があります：

### Xcodeで変更する場合（推奨）

1. Xcodeでプロジェクトを開く
   ```bash
   open ios/Runner.xcworkspace
   ```

2. 左側のプロジェクトナビゲーターで「Runner」を選択

3. 「TARGETS」の下の「Runner」を選択

4. 「General」タブで「Bundle Identifier」を変更
   - 例: `com.yourname.coffee` または `com.yourcompany.coffee`

5. 「Signing & Capabilities」タブで
   - Team: Apple Developer アカウントを選択
   - Automatically manage signing: チェックを入れる

### コマンドラインで変更する場合

プロジェクトルートで実行：

```bash
# Bundle IDを変更（yourname を自分の名前に変更）
sed -i '' 's/com.example.accountTemplate/com.yourname.coffee/g' ios/Runner.xcodeproj/project.pbxproj
```

## 3. 環境変数の確認

`.env` ファイルが正しく設定されているか確認：

```bash
cat .env
```

以下が設定されている必要があります：
- `SUPABASE_URL`: Supabaseプロジェクトのurl
- `SUPABASE_ANON_KEY`: Supabaseプロジェクトのanon key

## 4. デプロイ方法

### A. 実機で開発テスト（無料）

1. iPhoneをMacに接続

2. Xcodeで実行
   ```bash
   open ios/Runner.xcworkspace
   ```
   - 上部のデバイス選択で接続したiPhoneを選択
   - ▶️ ボタンをクリック

3. またはFlutterコマンドで
   ```bash
   # 接続されているデバイスを確認
   flutter devices

   # 実機で実行
   flutter run -d <デバイスID>
   ```

初回は「信頼されていない開発元」エラーが出る場合があります：
- iPhone: 設定 → 一般 → VPNとデバイス管理 → 開発元を信頼

### B. TestFlight（ベータテスト配布）

1. App Store Connect でアプリ登録
   - https://appstoreconnect.apple.com
   - 「マイApp」→「+」→ 新規App
   - Bundle IDを選択
   - App名、言語などを入力

2. アーカイブを作成
   ```bash
   # リリースビルドを作成
   flutter build ipa
   ```

3. Xcodeでアーカイブをアップロード
   ```bash
   open ios/Runner.xcworkspace
   ```
   - メニュー: Product → Archive
   - アーカイブ完了後、Organizer が開く
   - 「Distribute App」をクリック
   - 「App Store Connect」を選択
   - 「Upload」を選択
   - 指示に従ってアップロード

4. App Store Connect でTestFlightを設定
   - アップロード後、App Store Connect の TestFlight タブへ
   - テスターを招待（メールアドレス）
   - テスターはTestFlightアプリでインストール可能

### C. App Store リリース（本番公開）

TestFlightと同じ手順でアーカイブをアップロード後：

1. App Store Connect で「App Store」タブへ

2. 「+」→ 新しいバージョン作成

3. 必要情報を入力
   - App名
   - 説明文
   - スクリーンショット（必須）
   - プライバシーポリシーURL
   - サポートURL
   - カテゴリ

4. ビルドを選択
   - TestFlightでアップロードしたビルドを選択

5. 審査に提出
   - 「審査に提出」ボタンをクリック
   - 通常1-3日で審査結果が来る

## 5. トラブルシューティング

### コード署名エラー

```
Signing for "Runner" requires a development team.
```

**解決方法:**
- Xcode で Runner → Signing & Capabilities → Team を選択

### Provisioning Profile エラー

**解決方法:**
- Xcode で「Automatically manage signing」をオンにする

### .env ファイルが見つからない

**解決方法:**
```bash
cp .env.example .env
# .env を編集してSupabase情報を入力
```

### ビルドエラー: CocoaPods

**解決方法:**
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter build ios
```

## 6. ビルド番号の管理

リリースのたびにビルド番号を上げる必要があります：

### pubspec.yaml で管理

```yaml
version: 1.0.0+1  # 1.0.0 = バージョン名, +1 = ビルド番号
```

新しいリリースごとに：
- マイナーアップデート: `1.0.1+2`
- メジャーアップデート: `1.1.0+3`

### ビルド番号を自動で上げる

```bash
# pubspec.yaml のビルド番号をインクリメント
flutter pub get
```

## 参考リンク

- [Flutter iOS デプロイ公式ドキュメント](https://docs.flutter.dev/deployment/ios)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Program](https://developer.apple.com/programs/)
