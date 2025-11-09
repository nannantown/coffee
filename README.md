# Flutter + Supabase Authentication Template

再利用可能な完全な認証機能を備えたFlutterアプリテンプレート。メール認証に対応しています。

## ✨ 機能

- ✉️ **メール認証**: サインアップ、ログイン、パスワードリセット
- 🔄 **自動セッション管理**: トークンの自動更新と永続化
- 🎨 **Material 3 UI**: モダンで美しいデザイン
- 🌗 **ダーク/ライトテーマ**: システム設定に対応

## 🛠️ 技術スタック

- **Flutter** 3.x - UIフレームワーク
- **Supabase** - バックエンド（認証・データベース）
- **Riverpod** - 状態管理
- **GoRouter** - ルーティング
- **Material 3** - デザインシステム

## 📋 前提条件

- Flutter SDK 3.9.2以上
- Dart 3.x
- Supabaseアカウント

## 🚀 セットアップ手順

### 1. リポジトリのクローン

```bash
git clone <このリポジトリのURL>
cd account-template
```

### 2. 依存関係のインストール

```bash
flutter pub get
```

### 3. Supabaseプロジェクトの作成

1. [Supabase](https://app.supabase.com)にアクセスし、新しいプロジェクトを作成
2. **Settings > API**から以下の情報を取得:
   - Project URL
   - Anon/Public Key

3. **Authentication > Providers**で以下を有効化:
   - Email（デフォルトで有効）

4. **Authentication > URL Configuration**で以下を設定:
   - Redirect URLs: `io.supabase.flutterquickstart://reset-password/`

### 4. 環境変数の設定

1. `.env.example`をコピーして`.env`ファイルを作成:
   ```bash
   cp .env.example .env
   ```

2. `.env`ファイルを編集:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```

## 🎯 使い方

### アプリの実行

```bash
# 接続されたデバイス/エミュレータで実行
flutter run

# 特定のデバイスで実行
flutter run -d <device_id>
```

### ビルド

```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS（macOSが必要）
flutter build ios
```

## 📁 プロジェクト構造

```
lib/
├── main.dart                          # アプリエントリーポイント
├── config/
│   ├── supabase_config.dart          # Supabase初期化
│   └── router.dart                   # ルーティング設定
├── features/
│   └── auth/
│       ├── providers/
│       │   └── auth_provider.dart     # 認証状態管理
│       ├── services/
│       │   └── auth_service.dart      # 認証ロジック
│       └── screens/
│           ├── login_screen.dart      # ログイン画面
│           ├── signup_screen.dart     # サインアップ画面
│           ├── forgot_password_screen.dart  # パスワードリセット画面
│           └── home_screen.dart       # ホーム画面
└── core/
    └── constants/
        └── env.dart                   # 環境変数アクセス
```

## 🔧 カスタマイズ

### アプリ名の変更

1. `android/app/build.gradle.kts`の`applicationId`を変更
2. `ios/Runner/Info.plist`の`CFBundleDisplayName`を変更
3. Xcodeでバンドル識別子を変更

### テーマのカスタマイズ

`lib/main.dart`の`MaterialApp.router`内でテーマを変更:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,  // ここを変更
    brightness: Brightness.light,
  ),
  useMaterial3: true,
),
```

### 新機能の追加

1. `lib/features/`に新しいフィーチャーディレクトリを作成
2. `lib/config/router.dart`にルートを追加
3. Riverpodプロバイダーで状態管理
4. `ref.watch(currentUserProvider)`でログインユーザー情報にアクセス

## 🐛 トラブルシューティング

### 環境変数が読み込まれない

- `.env`ファイルがプロジェクトルートに存在するか確認
- `pubspec.yaml`に`.env`がアセットとして登録されているか確認
- アプリを再起動（ホットリロードでは環境変数は更新されない）

### ビルドエラー

```bash
# クリーンビルド
flutter clean
flutter pub get
flutter run
```

## 📝 ライセンス

このテンプレートは自由に使用・変更できます。

## 🤝 貢献

このテンプレートを改善するプルリクエストは歓迎します！

## 📚 参考リンク

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
