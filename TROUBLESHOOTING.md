# トラブルシューティングガイド

このドキュメントでは、プロジェクトのビルドと実行時に発生する可能性のある問題と解決策を説明します。

## iOS ビルドの問題

### エラー: "iOS 26.1 is not installed"

このエラーは、Xcodeプロジェクトの設定とシミュレータのバージョンの不一致が原因です。

#### 解決方法1: Xcodeから直接実行

1. Xcodeでプロジェクトを開く:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Xcodeで以下を確認:
   - **Runner** プロジェクトを選択
   - **Build Settings** タブを開く
   - **iOS Deployment Target** を `13.0` に設定
   - **Supported Platforms** を確認

3. シミュレータを選択して実行:
   - 上部のデバイス選択から任意のiOSシミュレータを選択
   - ⌘ + R でビルドと実行

#### 解決方法2: CocoaPodsの再インストール

```bash
cd ios
rm -rf Pods Podfile.lock .symlinks
arch -x86_64 pod install
cd ..
flutter clean
flutter pub get
```

#### 解決方法3: シミュレータの再起動

```bash
# 現在のシミュレータをシャットダウン
xcrun simctl shutdown all

# 別のシミュレータを起動
open -a Simulator

# Simulatorアプリから「File > Open Simulator」で任意のiPhoneを選択
```

その後、flutter runを実行:
```bash
flutter run
```

### CocoaPods FFI エラー

M1/M2 Mac でCocoaPodsの FFI エラーが発生する場合:

```bash
cd ios
arch -x86_64 pod install
cd ..
```

これにより、x86_64アーキテクチャでpod installが実行されます。

## Android ビルドの問題

## 環境変数の問題

### .envファイルが読み込まれない

1. `.env`ファイルがプロジェクトルートに存在することを確認:
   ```bash
   ls -la .env
   ```

2. ファイルの内容を確認:
   ```bash
   cat .env
   ```

3. アプリを完全に再起動（ホットリロードでは環境変数は更新されません）:
   ```bash
   flutter run
   ```

## Supabase接続の問題

### 認証エラーが発生する

1. `.env`ファイルの設定を確認:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

2. Supabaseダッシュボードで認証プロバイダーが有効になっていることを確認

3. ネットワーク接続を確認

### Deep Linkingが動作しない

#### iOS
1. `ios/Runner/Info.plist`でURLスキームが正しく設定されていることを確認
2. Supabaseダッシュボードの「Authentication > URL Configuration」で以下を設定:
   - Redirect URLs: `io.supabase.flutterquickstart://login-callback/`

#### Android
1. `android/app/build.gradle.kts`で`manifestPlaceholders`が設定されていることを確認:
   ```kotlin
   manifestPlaceholders["appAuthRedirectScheme"] = "io.supabase.flutterquickstart"
   ```

## 一般的な解決方法

### クリーンビルド

すべてをクリーンにして再ビルド:
```bash
flutter clean
flutter pub get
cd ios
arch -x86_64 pod install
cd ..
flutter run
```

### キャッシュのクリア

Flutter のキャッシュをクリア:
```bash
flutter pub cache clean
flutter pub get
```

### Flutter Doctorの実行

環境の問題を確認:
```bash
flutter doctor -v
```

## それでも解決しない場合

1. GitHub Issuesをチェック
2. Flutterの公式ドキュメントを参照
3. Supabaseの公式ドキュメントを参照
4. エラーメッセージを正確にGoogleで検索

## 開発環境の要件

- Flutter 3.9.2以上
- Dart 3.x
- Xcode 14.0以上（iOS開発の場合）
- Android Studio 2023.1以上（Android開発の場合）
- CocoaPods 1.11.0以上（iOS開発の場合）
