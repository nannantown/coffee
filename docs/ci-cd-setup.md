# CI/CD セットアップガイド

このプロジェクトでは **GitHub Actions** を使用して、Android APK/AAB と iOS IPA の自動ビルド、およびTestFlightへの自動アップロードを実現しています。

## 📋 目次

- [概要](#概要)
- [必要な準備](#必要な準備)
- [Android セットアップ](#android-セットアップ)
- [iOS セットアップ](#ios-セットアップ)
- [GitHub Secrets 設定](#github-secrets-設定)
- [使い方](#使い方)
- [トラブルシューティング](#トラブルシューティング)
- [コスト試算](#コスト試算)

---

## 概要

### 自動化されている内容

✅ **Android**
- PR作成時: テスト・Lint実行
- mainブランチpush時: APKビルド & アーティファクトアップロード
- タグpush時: AAB（App Bundle）ビルド & アーティファクトアップロード

✅ **iOS**
- タグpush時: IPAビルド & TestFlightへ自動アップロード

### 無料枠での運用

**GitHub Actions 無料枠（プライベートリポジトリ）:**
- 月間 2,000分（macOS換算で200分）
- Androidビルド（Linux）: 完全無料
- iOSビルド（macOS）: 月13〜20回程度実行可能

**パブリックリポジトリ:** 無制限・完全無料

---

## 必要な準備

### 必須コスト

| 項目 | 金額 | 頻度 |
|------|------|------|
| **Apple Developer Program** | **$99** | **年間** |
| **Google Play Developer** | **$25** | **初回のみ** |

**合計:** 初年度 $124、2年目以降 $99/年

### 必要なアカウント

1. **Apple Developer Account** - iOS開発・TestFlight配信に必須
2. **Google Play Console Account** - Android配信に必須
3. **GitHub Account** - CI/CD実行に必須

---

## Android セットアップ

### 1. キーストアの生成

```bash
# リリース用キーストアを生成
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# 質問に答えて情報を入力
# - パスワード: 安全なパスワードを設定（記録する）
# - 名前、組織、場所などの情報を入力
```

**重要:** 生成したキーストアとパスワードは**絶対に失くさないでください**。失うとアプリの更新ができなくなります。

### 2. キーストアのBase64エンコード

```bash
# macOS/Linux
base64 -i upload-keystore.jks | pbcopy

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

### 3. GitHub Secrets に登録

リポジトリの Settings → Secrets and variables → Actions から以下を追加:

| Secret Name | 内容 |
|------------|------|
| `KEYSTORE_BASE64` | Base64エンコードしたキーストア |
| `KEY_PASSWORD` | キーストアのパスワード |
| `ALIAS_PASSWORD` | エイリアスのパスワード（通常はKEY_PASSWORDと同じ） |
| `KEY_ALIAS` | エイリアス名（デフォルト: `upload`） |

### 4. ローカルでのビルド確認（オプション）

```bash
# key.properties ファイルを作成（gitignoreされています）
cat > android/key.properties << EOF
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
EOF

# キーストアを配置
cp upload-keystore.jks android/app/

# リリースビルド
flutter build apk --release
flutter build appbundle --release
```

---

## iOS セットアップ

### 前提条件

- ✅ Apple Developer Program 登録完了
- ✅ App Store Connect でアプリ作成完了
- ✅ Bundle Identifier が設定済み（現在: `com.example.account_template`）

### 1. Fastlane Match 初期化

**Matchとは:** iOSの証明書とプロビジョニングプロファイルを安全にGitリポジトリで管理するツール

#### 1.1 証明書管理用の**プライベート**Gitリポジトリを作成

GitHub で新しいプライベートリポジトリを作成:
- リポジトリ名例: `ios-certificates`
- **必ずPrivateに設定**
- README不要

#### 1.2 Matchの初期化

```bash
cd ios
gem install fastlane
fastlane match init
```

質問に答える:
1. `git` を選択
2. GitリポジトリのURL を入力（例: `git@github.com:yourname/ios-certificates.git`）

#### 1.3 証明書の生成

```bash
# App Store用証明書とプロビジョニングプロファイルを生成
fastlane match appstore
```

質問に答える:
1. **Passphrase**: 暗号化用のパスワード（記録する、GitHub Secretsに使用）
2. **Apple ID**: 開発者アカウントのメールアドレス
3. **App-specific password**: App Store Connect API用（後述）

### 2. App-specific Password の生成

1. [Apple ID アカウント](https://appleid.apple.com/) にサインイン
2. **セキュリティ** → **App用パスワード**
3. パスワードを生成（名前: `fastlane`）
4. 生成されたパスワードをコピー（GitHub Secretsに使用）

### 3. App Store Connect API Key の作成

1. [App Store Connect](https://appstoreconnect.apple.com/) → Users and Access → Keys
2. **Generate API Key** をクリック
3. 名前: `GitHub Actions`、アクセス権限: **App Manager** 以上
4. **Download API Key** （`.p8`ファイル）

### 4. SSH鍵の生成（Match用）

```bash
# 新しいSSH鍵を生成
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/match_deploy_key

# 公開鍵を証明書リポジトリに登録
cat ~/.ssh/match_deploy_key.pub
# → GitHubの証明書リポジトリ Settings → Deploy keys に追加（Write accessを有効化）

# 秘密鍵をコピー（GitHub Secretsに使用）
cat ~/.ssh/match_deploy_key | pbcopy
```

### 5. GitHub Secrets に登録

| Secret Name | 内容 |
|------------|------|
| `MATCH_PASSWORD` | Matchの暗号化パスワード |
| `MATCH_GIT_URL` | 証明書リポジトリのSSH URL（`git@github.com:...`） |
| `MATCH_GIT_PRIVATE_KEY` | SSH秘密鍵全文 |
| `FASTLANE_APPLE_ID` | Apple IDメールアドレス |
| `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | App用パスワード |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID（App Store Connectから取得） |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID（App Store Connectから取得） |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | `.p8`ファイルの内容（Base64エンコード） |

**API Keyのエンコード:**
```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

### 6. Fastfile の調整（必要に応じて）

`ios/fastlane/Appfile` のBundle Identifierを確認:
```ruby
app_identifier("com.example.account_template") # 実際のBundle IDに変更
```

---

## GitHub Secrets 設定

### Secretsの登録方法

1. GitHubリポジトリページ → **Settings**
2. 左サイドバー → **Secrets and variables** → **Actions**
3. **New repository secret** をクリック
4. Name と Secret を入力して **Add secret**

### 設定する全Secrets一覧

#### Android用

| Name | 説明 | 取得方法 |
|------|------|---------|
| `KEYSTORE_BASE64` | Base64エンコードされたキーストア | `base64 upload-keystore.jks` |
| `KEY_PASSWORD` | キーストアのパスワード | keytool生成時に設定 |
| `ALIAS_PASSWORD` | エイリアスのパスワード | keytool生成時に設定 |
| `KEY_ALIAS` | エイリアス名 | デフォルト: `upload` |

#### iOS用

| Name | 説明 | 取得方法 |
|------|------|---------|
| `MATCH_PASSWORD` | Match暗号化パスワード | `fastlane match init`時に設定 |
| `MATCH_GIT_URL` | 証明書リポジトリSSH URL | `git@github.com:yourname/ios-certificates.git` |
| `MATCH_GIT_PRIVATE_KEY` | SSH秘密鍵 | `ssh-keygen`で生成 |
| `FASTLANE_APPLE_ID` | Apple IDメールアドレス | Apple Developer Account |
| `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | App用パスワード | appleid.apple.comで生成 |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID | App Store Connect → Keys |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID | App Store Connect → Keys |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64エンコードされた.p8ファイル | `base64 AuthKey_XXX.p8` |

---

## 使い方

### Android APK ビルド

```bash
# mainブランチにpush
git push origin main

# → GitHub Actionsが自動で:
# 1. テスト実行
# 2. APKビルド
# 3. Artifactsにアップロード
```

### Android App Bundle ビルド

```bash
# バージョンタグを作成してpush
git tag v1.0.0
git push origin v1.0.0

# → GitHub Actionsが自動で:
# 1. テスト実行
# 2. AABビルド
# 3. Artifactsにアップロード
```

### iOS TestFlight アップロード

```bash
# バージョンタグを作成してpush
git tag v1.0.0
git push origin v1.0.0

# → GitHub Actionsが自動で:
# 1. Flutterビルド
# 2. Xcode Archive
# 3. TestFlightにアップロード
```

### ビルド成果物のダウンロード

1. GitHubリポジトリ → **Actions** タブ
2. 該当のワークフロー実行をクリック
3. **Artifacts** セクションからダウンロード

---

## トラブルシューティング

### Android関連

#### エラー: `Keystore file not found`

**原因:** GitHub SecretsにKEYSTORE_BASE64が設定されていない

**解決策:**
```bash
# キーストアを再エンコード
base64 -i upload-keystore.jks | pbcopy
# GitHub SecretsにKEYSTORE_BASE64として登録
```

#### エラー: `Incorrect keystore password`

**原因:** パスワードが間違っている、または特殊文字のエスケープが必要

**解決策:**
- GitHub SecretsのKEY_PASSWORDとALIAS_PASSWORDを確認
- 特殊文字（`$`, `!`, `\`など）はエスケープが必要な場合がある

### iOS関連

#### エラー: `No signing certificate found`

**原因:** Matchの証明書が取得できていない

**解決策:**
```bash
# ローカルで証明書を確認
cd ios
fastlane match appstore --readonly

# GitHub Secretsを確認:
# - MATCH_PASSWORD
# - MATCH_GIT_URL
# - MATCH_GIT_PRIVATE_KEY
```

#### エラー: `Authentication failed`

**原因:** Apple IDの認証情報が間違っている

**解決策:**
- FASTLANE_APPLE_ID が正しいか確認
- App用パスワードを再生成してFASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORDを更新

#### エラー: `Could not find App with bundle identifier`

**原因:** App Store Connectでアプリが作成されていない

**解決策:**
1. App Store Connectにログイン
2. **マイApp** → **新規App** からアプリを作成
3. Bundle ID、アプリ名などを設定

#### エラー: `SSH: Permission denied`

**原因:** SSH鍵が証明書リポジトリに登録されていない

**解決策:**
1. 証明書リポジトリ Settings → Deploy keys
2. SSH公開鍵を追加（Write accessを有効化）

### 共通

#### ビルド時間が長すぎる

**対策:**
- PR時はテストのみ実行（ビルドしない）
- タグpush時のみフルビルド実行
- キャッシュを有効化（既に設定済み）

#### GitHub Actions の無料枠を超過

**症状:** macOS runnerの実行時間が月200分を超える

**対策:**
1. **タグpush時のみiOSビルド** - 頻繁なビルドを避ける
2. **パブリックリポジトリ化** - 無制限無料（機密情報は削除必要）
3. **セルフホストランナー** - 自前Macでビルド（初期投資あり）
4. **超過分購入** - $0.08/分（macOS）

---

## コスト試算

### プライベートリポジトリでの月間コスト

**想定シナリオ:**
- Android PR: 20回/月 × 5分 = 100分（Linux）
- Android リリース: 4回/月 × 10分 = 40分（Linux）
- iOS リリース: 4回/月 × 15分 = 60分（macOS）

**消費分数:**
- Linux: 140分（そのまま）
- macOS: 60分 × 10倍 = 600分相当

**合計: 740分 / 月 → 無料枠内（2,000分）**

### 年間必須コスト

| 項目 | 金額 | 備考 |
|------|------|------|
| Apple Developer Program | $99/年 | TestFlight必須 |
| Google Play Developer | $25（初回のみ） | Play Store必須 |
| GitHub Actions | $0 | 無料枠内 |
| **合計（初年度）** | **$124** | **約18,600円** |
| **合計（2年目以降）** | **$99/年** | **約14,850円/年** |

---

## さらなる最適化

### パブリックリポジトリ化（完全無料）

機密情報（`.env`、Supabase設定）をGitHub Secretsに移行して、リポジトリをパブリック化すると:
- ✅ GitHub Actions 完全無料・無制限
- ✅ Flutter認証テンプレートとしてOSS化
- ✅ コミュニティからのコントリビューション

### セルフホストランナー

自前のMac（Mac miniなど）でビルドすると:
- ✅ iOSビルド無制限
- ❌ 初期投資: 約10万円
- 月20回以上iOSビルドで元が取れる

---

## 参考リンク

- [GitHub Actions 料金](https://docs.github.com/billing/managing-billing-for-github-actions/about-billing-for-github-actions)
- [Fastlane公式ドキュメント](https://docs.fastlane.tools/)
- [Flutter CI/CDガイド](https://docs.flutter.dev/deployment/cd)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)

---

## サポート

問題が発生した場合:
1. GitHub ActionsのログをActions画面で確認
2. 上記トラブルシューティングを参照
3. [Issues](../../issues)で質問・報告

Happy coding! 🚀
