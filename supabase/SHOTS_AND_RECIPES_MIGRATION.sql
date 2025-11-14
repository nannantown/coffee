-- ショットとレシピの実装マイグレーション
-- ショット: 毎回のエスプレッソショットを記録
-- レシピ: 良いショットをレシピとして保存

-- 1. espresso_shotsテーブル作成（ショット記録用）
CREATE TABLE IF NOT EXISTS public.espresso_shots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    coffee_weight DECIMAL(5, 2) NOT NULL,
    grinder_setting TEXT NOT NULL,
    extraction_time INTEGER,
    roast_level DECIMAL(3, 2),
    rating INTEGER NOT NULL DEFAULT 3,
    appearance_rating INTEGER NOT NULL DEFAULT 3,
    taste_rating INTEGER NOT NULL DEFAULT 3,
    notes TEXT,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. espresso_recipesテーブル作成（レシピ保存用）
CREATE TABLE IF NOT EXISTS public.espresso_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    source_shot_id UUID REFERENCES public.espresso_shots(id) ON DELETE SET NULL,
    coffee_weight DECIMAL(5, 2) NOT NULL,
    grinder_setting TEXT NOT NULL,
    extraction_time INTEGER,
    roast_level DECIMAL(3, 2),
    rating INTEGER NOT NULL DEFAULT 3,
    appearance_rating INTEGER NOT NULL DEFAULT 3,
    taste_rating INTEGER NOT NULL DEFAULT 3,
    notes TEXT,
    photo_url TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. インデックス作成
CREATE INDEX IF NOT EXISTS idx_espresso_shots_group_id ON public.espresso_shots(group_id);
CREATE INDEX IF NOT EXISTS idx_espresso_shots_created_by ON public.espresso_shots(created_by);
CREATE INDEX IF NOT EXISTS idx_espresso_shots_created_at ON public.espresso_shots(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_espresso_recipes_group_id ON public.espresso_recipes(group_id);
CREATE INDEX IF NOT EXISTS idx_espresso_recipes_created_by ON public.espresso_recipes(created_by);
CREATE INDEX IF NOT EXISTS idx_espresso_recipes_created_at ON public.espresso_recipes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_espresso_recipes_is_favorite ON public.espresso_recipes(is_favorite);
CREATE INDEX IF NOT EXISTS idx_espresso_recipes_source_shot_id ON public.espresso_recipes(source_shot_id);

-- 4. RLS (Row Level Security) ポリシー設定

-- espresso_shots のRLSを有効化
ALTER TABLE public.espresso_shots ENABLE ROW LEVEL SECURITY;

-- espresso_shotsの読み取り: グループメンバーのみ
CREATE POLICY "Users can view shots in their groups"
    ON public.espresso_shots FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.group_members
            WHERE group_members.group_id = espresso_shots.group_id
            AND group_members.user_id = auth.uid()
        )
    );

-- espresso_shotsの作成: グループメンバーのみ
CREATE POLICY "Users can create shots in their groups"
    ON public.espresso_shots FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.group_members
            WHERE group_members.group_id = espresso_shots.group_id
            AND group_members.user_id = auth.uid()
        )
        AND created_by = auth.uid()
    );

-- espresso_shotsの更新: 作成者のみ
CREATE POLICY "Users can update their own shots"
    ON public.espresso_shots FOR UPDATE
    USING (created_by = auth.uid())
    WITH CHECK (created_by = auth.uid());

-- espresso_shotsの削除: 作成者のみ
CREATE POLICY "Users can delete their own shots"
    ON public.espresso_shots FOR DELETE
    USING (created_by = auth.uid());

-- espresso_recipes のRLSを有効化
ALTER TABLE public.espresso_recipes ENABLE ROW LEVEL SECURITY;

-- espresso_recipesの読み取り: グループメンバーのみ
CREATE POLICY "Users can view recipes in their groups"
    ON public.espresso_recipes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.group_members
            WHERE group_members.group_id = espresso_recipes.group_id
            AND group_members.user_id = auth.uid()
        )
    );

-- espresso_recipesの作成: グループメンバーのみ
CREATE POLICY "Users can create recipes in their groups"
    ON public.espresso_recipes FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.group_members
            WHERE group_members.group_id = espresso_recipes.group_id
            AND group_members.user_id = auth.uid()
        )
        AND created_by = auth.uid()
    );

-- espresso_recipesの更新: 作成者のみ（ただしis_favoriteはグループメンバー全員が変更可能）
CREATE POLICY "Users can update their own recipes"
    ON public.espresso_recipes FOR UPDATE
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.group_members
            WHERE group_members.group_id = espresso_recipes.group_id
            AND group_members.user_id = auth.uid()
        )
    )
    WITH CHECK (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.group_members
            WHERE group_members.group_id = espresso_recipes.group_id
            AND group_members.user_id = auth.uid()
        )
    );

-- espresso_recipesの削除: 作成者のみ
CREATE POLICY "Users can delete their own recipes"
    ON public.espresso_recipes FOR DELETE
    USING (created_by = auth.uid());

-- 5. ユーザー名付きでデータを取得する関数

-- ショット一覧を取得（ユーザー名付き）
CREATE OR REPLACE FUNCTION get_shots_with_usernames(p_group_id UUID)
RETURNS TABLE (
    id UUID,
    group_id UUID,
    created_by UUID,
    created_by_username TEXT,
    coffee_weight DECIMAL,
    grinder_setting TEXT,
    extraction_time INTEGER,
    roast_level DECIMAL,
    rating INTEGER,
    appearance_rating INTEGER,
    taste_rating INTEGER,
    notes TEXT,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        s.group_id,
        s.created_by,
        COALESCE(p.username, 'Unknown') as created_by_username,
        s.coffee_weight,
        s.grinder_setting,
        s.extraction_time,
        s.roast_level,
        s.rating,
        s.appearance_rating,
        s.taste_rating,
        s.notes,
        s.photo_url,
        s.created_at,
        s.updated_at
    FROM public.espresso_shots s
    LEFT JOIN public.profiles p ON s.created_by = p.id
    WHERE s.group_id = p_group_id
    ORDER BY s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- レシピ一覧を取得（ユーザー名付き）
CREATE OR REPLACE FUNCTION get_recipes_with_usernames(p_group_id UUID)
RETURNS TABLE (
    id UUID,
    group_id UUID,
    created_by UUID,
    created_by_username TEXT,
    source_shot_id UUID,
    coffee_weight DECIMAL,
    grinder_setting TEXT,
    extraction_time INTEGER,
    roast_level DECIMAL,
    rating INTEGER,
    appearance_rating INTEGER,
    taste_rating INTEGER,
    notes TEXT,
    photo_url TEXT,
    is_favorite BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id,
        r.group_id,
        r.created_by,
        COALESCE(p.username, 'Unknown') as created_by_username,
        r.source_shot_id,
        r.coffee_weight,
        r.grinder_setting,
        r.extraction_time,
        r.roast_level,
        r.rating,
        r.appearance_rating,
        r.taste_rating,
        r.notes,
        r.photo_url,
        r.is_favorite,
        r.created_at,
        r.updated_at
    FROM public.espresso_recipes r
    LEFT JOIN public.profiles p ON r.created_by = p.id
    WHERE r.group_id = p_group_id
    ORDER BY r.is_favorite DESC, r.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
