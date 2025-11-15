-- マイグレーション: group_membersテーブルにdisplay_orderカラムを追加
-- グループリストの並び替え機能のため

-- display_orderカラムを追加
ALTER TABLE group_members
ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;

-- 既存のレコードにdisplay_orderを設定（joined_atの順序を維持）
WITH ranked_members AS (
  SELECT
    id,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY joined_at) - 1 AS order_num
  FROM group_members
)
UPDATE group_members
SET display_order = ranked_members.order_num
FROM ranked_members
WHERE group_members.id = ranked_members.id;

-- インデックスを追加してソートのパフォーマンスを向上
CREATE INDEX IF NOT EXISTS idx_group_members_user_display_order
ON group_members(user_id, display_order);
