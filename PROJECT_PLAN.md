# エスプレッソレシピ記録アプリ実装計画

## 概要

コーヒーグループを作成し、メンバー間でエスプレッソレシピを共有・記録するアプリ。Supabase をバックエンドとして使用。

## データベース設計（Supabase）

### テーブル構成

1. **coffee_groups** テーブル

   - id (uuid, primary key)
   - name (text, not null) - グループ名
   - owner_id (uuid, foreign key → auth.users) - 作成者 ID
   - created_at (timestamp)
   - updated_at (timestamp)

2. **group_members** テーブル

   - id (uuid, primary key)
   - group_id (uuid, foreign key → coffee_groups)
   - user_id (uuid, foreign key → auth.users)
   - role (text) - 'owner' or 'member'
   - joined_at (timestamp)
   - ユニーク制約: (group_id, user_id)

3. **group_invitations** テーブル

   - id (uuid, primary key)
   - group_id (uuid, foreign key → coffee_groups)
   - invite_code (text, unique) - 招待リンク用のコード
   - created_by (uuid, foreign key → auth.users)
   - expires_at (timestamp, optional)
   - created_at (timestamp)

4. **espresso_recipes** テーブル
   - id (uuid, primary key)
   - group_id (uuid, foreign key → coffee_groups)
   - created_by (uuid, foreign key → auth.users)
   - coffee_weight (numeric, not null) - g 数
   - grinder_setting (text, not null) - グラインダーセッテイング（3 桁の数字）
   - extraction_time (integer, optional) - 抽出時間（秒）
   - roast_level (numeric, optional) - 焙煎度（0.0-1.0）
   - rating (integer, not null) - 結果評価（1-5）
   - photo_url (text, optional) - 写真の URL
   - created_at (timestamp, not null) - 自動記録
   - updated_at (timestamp)

## 実装ファイル構成

### 新規作成ファイル

1. **lib/features/groups/**

   - `models/coffee_group.dart` - グループモデル
   - `models/group_member.dart` - メンバーモデル
   - `models/group_invitation.dart` - 招待モデル
   - `services/group_service.dart` - グループ CRUD 操作
   - `services/invitation_service.dart` - 招待リンク生成・参加処理
   - `providers/group_provider.dart` - Riverpod プロバイダー
   - `screens/groups_list_screen.dart` - グループ一覧画面
   - `screens/group_detail_screen.dart` - グループ詳細画面（レシピ一覧含む）
   - `screens/create_group_screen.dart` - グループ作成画面
   - `screens/join_group_screen.dart` - 招待リンクで参加する画面

2. **lib/features/recipes/**

   - `models/espresso_recipe.dart` - レシピモデル
   - `services/recipe_service.dart` - レシピ CRUD 操作
   - `services/storage_service.dart` - Supabase Storage 操作（写真アップロード）
   - `providers/recipe_provider.dart` - Riverpod プロバイダー
   - `screens/create_recipe_screen.dart` - レシピ作成画面
   - `screens/edit_recipe_screen.dart` - レシピ編集画面
   - `widgets/recipe_form.dart` - レシピ入力フォーム（共通ウィジェット）
   - `widgets/recipe_list_item.dart` - レシピ一覧アイテム

3. **lib/core/utils/**
   - `image_picker_util.dart` - 画像選択ユーティリティ

### 修正ファイル

1. **lib/config/router.dart** - 新しいルートを追加
2. **lib/features/auth/screens/home_screen.dart** - グループ一覧へのナビゲーション追加
3. **pubspec.yaml** - 必要なパッケージ追加（image_picker 等）

## 主要機能実装

### 1. グループ機能

- グループ作成（作成者が owner）
- グループ一覧表示（ユーザーが参加しているグループ）
- グループ詳細表示
- グループ削除（owner のみ）

### 2. 招待機能

- 招待リンク生成（ランダムなコード生成）
- 招待リンクでグループ参加
- 招待リンクの共有（クリップボードにコピー）

### 3. レシピ機能

- レシピ作成（必須: g 数、グラインダーセッテイング、評価 / 任意: 抽出時間、焙煎度、写真）
- レシピ一覧表示（グループ詳細内）
- レシピ削除
- 写真アップロード（Supabase Storage）

### 4. UI/UX

- グループ一覧 → グループ詳細（レシピ一覧） → レシピ作成/編集の画面遷移
- スライダーで焙煎度入力（0-100%）
- 5 段階評価（星表示）
- 写真選択・プレビュー機能

## 必要なパッケージ追加

- `image_picker` - 写真選択
- `uuid` - 招待コード生成
- `share_plus` - 招待リンク共有（オプション）

## Supabase 設定

1. RLS（Row Level Security）ポリシー設定
2. Storage バケット作成（`recipe-photos`）
3. Storage ポリシー設定

## 実装タスク

1. pubspec.yaml に必要なパッケージ（image_picker, uuid 等）を追加
2. グループ、メンバー、招待、レシピのモデルクラスを作成
3. グループ、招待、レシピ、ストレージのサービスクラスを作成
4. Riverpod プロバイダーを作成
5. グループ一覧、詳細、作成、参加画面を作成
6. レシピ作成、編集画面とフォームウィジェットを作成
7. ルーターに新しい画面のルートを追加
8. ホーム画面からグループ一覧へのナビゲーションを追加
