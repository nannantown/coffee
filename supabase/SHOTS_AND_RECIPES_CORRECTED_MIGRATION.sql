-- Migration to add rating columns to espresso_shots and create espresso_recipes table
-- Fixes: References coffee_groups instead of groups, adds missing rating columns

-- ============================================================================
-- 1. ALTER espresso_shots table to add missing rating columns
-- ============================================================================

-- Add rating columns if they don't exist
ALTER TABLE public.espresso_shots
ADD COLUMN IF NOT EXISTS rating INTEGER NOT NULL DEFAULT 3,
ADD COLUMN IF NOT EXISTS appearance_rating INTEGER NOT NULL DEFAULT 3,
ADD COLUMN IF NOT EXISTS taste_rating INTEGER NOT NULL DEFAULT 3;

-- Add constraints for rating values (1-5)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'espresso_shots_rating_check'
    ) THEN
        ALTER TABLE public.espresso_shots
        ADD CONSTRAINT espresso_shots_rating_check
        CHECK (rating >= 1 AND rating <= 5);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'espresso_shots_appearance_rating_check'
    ) THEN
        ALTER TABLE public.espresso_shots
        ADD CONSTRAINT espresso_shots_appearance_rating_check
        CHECK (appearance_rating >= 1 AND appearance_rating <= 5);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'espresso_shots_taste_rating_check'
    ) THEN
        ALTER TABLE public.espresso_shots
        ADD CONSTRAINT espresso_shots_taste_rating_check
        CHECK (taste_rating >= 1 AND taste_rating <= 5);
    END IF;
END $$;

-- ============================================================================
-- 2. CREATE espresso_recipes table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.espresso_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.coffee_groups(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    source_shot_id UUID REFERENCES public.espresso_shots(id) ON DELETE SET NULL,
    coffee_weight DECIMAL(5, 2) NOT NULL,
    grinder_setting TEXT NOT NULL,
    extraction_time INTEGER,
    roast_level DECIMAL(3, 2),
    rating INTEGER NOT NULL DEFAULT 3,
    appearance_rating INTEGER NOT NULL DEFAULT 3,
    taste_rating INTEGER NOT NULL DEFAULT 3,
    is_favorite BOOLEAN DEFAULT false,
    notes TEXT,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT espresso_recipes_rating_check CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT espresso_recipes_appearance_rating_check CHECK (appearance_rating >= 1 AND appearance_rating <= 5),
    CONSTRAINT espresso_recipes_taste_rating_check CHECK (taste_rating >= 1 AND taste_rating <= 5)
);

-- ============================================================================
-- 3. CREATE indexes for performance
-- ============================================================================

-- Shots indexes
CREATE INDEX IF NOT EXISTS idx_espresso_shots_group_id ON public.espresso_shots(group_id);
CREATE INDEX IF NOT EXISTS idx_espresso_shots_created_by ON public.espresso_shots(created_by);
CREATE INDEX IF NOT EXISTS idx_espresso_shots_created_at ON public.espresso_shots(created_at DESC);

-- Recipes indexes
CREATE INDEX IF NOT EXISTS idx_espresso_recipes_group_id ON public.espresso_recipes(group_id);
CREATE INDEX IF NOT EXISTS idx_espresso_recipes_created_by ON public.espresso_recipes(created_by);
CREATE INDEX IF NOT EXISTS idx_espresso_recipes_source_shot_id ON public.espresso_recipes(source_shot_id);
CREATE INDEX IF NOT EXISTS idx_espresso_recipes_is_favorite ON public.espresso_recipes(is_favorite);
CREATE INDEX IF NOT EXISTS idx_espresso_recipes_created_at ON public.espresso_recipes(created_at DESC);

-- ============================================================================
-- 4. ENABLE Row Level Security (RLS)
-- ============================================================================

ALTER TABLE public.espresso_recipes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. CREATE RLS policies for espresso_recipes
-- ============================================================================

-- Allow users to view recipes in groups they're members of
DROP POLICY IF EXISTS "Users can view recipes in their groups" ON public.espresso_recipes;
CREATE POLICY "Users can view recipes in their groups"
ON public.espresso_recipes FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.group_members
        WHERE group_members.group_id = espresso_recipes.group_id
        AND group_members.user_id = auth.uid()
    )
);

-- Allow users to create recipes in groups they're members of
DROP POLICY IF EXISTS "Users can create recipes in their groups" ON public.espresso_recipes;
CREATE POLICY "Users can create recipes in their groups"
ON public.espresso_recipes FOR INSERT
WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.group_members
        WHERE group_members.group_id = espresso_recipes.group_id
        AND group_members.user_id = auth.uid()
    )
);

-- Allow users to update their own recipes
DROP POLICY IF EXISTS "Users can update their own recipes" ON public.espresso_recipes;
CREATE POLICY "Users can update their own recipes"
ON public.espresso_recipes FOR UPDATE
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- Allow users to delete their own recipes
DROP POLICY IF EXISTS "Users can delete their own recipes" ON public.espresso_recipes;
CREATE POLICY "Users can delete their own recipes"
ON public.espresso_recipes FOR DELETE
USING (created_by = auth.uid());

-- ============================================================================
-- 6. CREATE helper function to get shots with usernames
-- ============================================================================

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

-- ============================================================================
-- 7. CREATE helper function to get recipes with usernames
-- ============================================================================

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
    is_favorite BOOLEAN,
    notes TEXT,
    photo_url TEXT,
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
        r.is_favorite,
        r.notes,
        r.photo_url,
        r.created_at,
        r.updated_at
    FROM public.espresso_recipes r
    LEFT JOIN public.profiles p ON r.created_by = p.id
    WHERE r.group_id = p_group_id
    ORDER BY r.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 8. CREATE trigger to update updated_at timestamp
-- ============================================================================

-- Create update timestamp function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger for espresso_recipes
DROP TRIGGER IF EXISTS update_espresso_recipes_updated_at ON public.espresso_recipes;
CREATE TRIGGER update_espresso_recipes_updated_at
    BEFORE UPDATE ON public.espresso_recipes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
