# Supabase Edge Function デプロイ手順

## 前提条件
- Supabase CLIがインストールされていること
- プロジェクトにログインしていること

## 1. Supabase CLIのインストール（未インストールの場合）

```bash
# macOSの場合
brew install supabase/tap/supabase

# または npm経由
npm install -g supabase
```

## 2. Supabaseプロジェクトにログイン

```bash
supabase login
```

ブラウザが開くので、Supabaseアカウントでログインしてください。

## 3. プロジェクトをリンク

```bash
cd /Users/kokinaniwa/projects/coffee
supabase link --project-ref YOUR_PROJECT_REF
```

**YOUR_PROJECT_REF**の確認方法:
- Supabase Dashboard → Settings → General → Reference ID

## 4. Edge Functionをデプロイ

```bash
supabase functions deploy delete-user-account
```

デプロイが成功すると、以下のようなメッセージが表示されます:
```
Deployed Function delete-user-account on project YOUR_PROJECT
```

## 5. 環境変数の確認（自動設定されます）

Edge Functionは以下の環境変数を使用します（Supabaseが自動で設定）:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

## 6. テスト

アプリから以下の手順でテストできます:

1. グループ一覧画面の右上メニュー（⋮）をタップ
2. 「全データ削除」を選択
3. 2回の確認ダイアログで「削除する」「完全に削除」をタップ
4. アカウントとすべてのデータが削除され、ログイン画面に戻ります

## トラブルシューティング

### Edge Functionのログを確認

```bash
supabase functions logs delete-user-account
```

### 手動でテスト（curlコマンド）

```bash
curl -i --location --request POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/delete-user-account' \
  --header 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  --header 'Content-Type: application/json'
```

### よくあるエラー

**Error: Missing authorization header**
- アプリから正しく認証トークンが送信されていません
- AuthService.deleteAccount()の実装を確認

**Error: Failed to delete user data**
- SQLのdelete_own_data関数が存在しない、または権限エラー
- Supabase Dashboard → SQL Editorで関数を確認

**Error: Failed to delete user account**
- SERVICE_ROLE_KEYの権限不足
- Edge Functionが正しくデプロイされていない可能性

## 参考リンク
- [Supabase Edge Functions Documentation](https://supabase.com/docs/guides/functions)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli/introduction)
