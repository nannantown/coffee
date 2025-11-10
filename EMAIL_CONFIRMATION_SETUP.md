# メール確認ページのセットアップ手順

新規登録時のメール確認リンクをGitHub Pagesでホストされた確認完了ページにリダイレクトする設定手順です。

## 1. GitHub Pagesを有効化

1. GitHubリポジトリ（https://github.com/nannantown/coffee）を開く

2. **Settings** タブをクリック

3. 左サイドバーから **Pages** を選択

4. **Source** セクションで以下を設定：
   - Branch: `main` (または `master`)
   - Folder: `/docs`
   - **Save** をクリック

5. 数分待つと、以下のURLで公開されます：
   ```
   https://nannantown.github.io/coffee/email-confirmed.html
   ```

6. URLをブラウザで開いて、確認完了ページが表示されることを確認

## 2. Supabaseの設定

### A. Redirect URLsの追加

1. Supabaseダッシュボード（https://app.supabase.com）を開く

2. プロジェクト（qsuzfdpxyljkufxhcllv）を選択

3. 左サイドバーから **Authentication** → **URL Configuration** を選択

4. **Redirect URLs** セクションに以下を追加：
   ```
   https://nannantown.github.io/coffee/email-confirmed.html
   ```

5. **Save** をクリック

### B. Site URLの設定

同じ **URL Configuration** ページで：

1. **Site URL** を以下に設定：
   ```
   https://nannantown.github.io/coffee/email-confirmed.html
   ```

2. **Save** をクリック

## 3. 動作確認

1. アプリで新規登録を実行

2. 登録したメールアドレスに確認メールが届く

3. メール内の **Confirm your mail** リンクをクリック

4. GitHub Pagesの確認完了ページが表示される
   - 「メール確認完了」のメッセージ
   - アプリに戻る手順

5. アプリを開いてログイン

## トラブルシューティング

### GitHub Pagesが404エラーになる

- リポジトリ設定でPagesが正しく有効化されているか確認
- `main`ブランチに`docs/email-confirmed.html`がコミット・プッシュされているか確認
- 公開まで数分かかる場合があるので待つ

### メール確認リンクがlocalhostに飛ぶ

- Supabaseの**Redirect URLs**に正しいURLが追加されているか確認
- **Site URL**が正しく設定されているか確認
- 設定を保存した後、新しく登録を試す（古い登録メールは設定前のURLを使用）

### メール確認リンクが機能しない

- Supabaseプロジェクトが**Paused**状態になっていないか確認
- Authentication設定で**Enable email confirmations**が有効になっているか確認

## 注意事項

- GitHub Pagesの公開には数分かかる場合があります
- 設定変更後は新しく登録したメールで確認してください
- 既存の確認メールは古いリダイレクト設定を使用します

## 今後の拡張

将来的に以下の機能を追加できます：

- App StoreやGoogle Playへのリンク追加
- ブランドロゴやカラーの適用
- アプリのディープリンクでアプリを直接開く
- 多言語対応（英語版の追加など）
