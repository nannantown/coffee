-- Migration to update get_shots_with_usernames function to include group image URL

-- Drop and recreate the function with group_image_url
DROP FUNCTION IF EXISTS get_shots_with_usernames(UUID);

CREATE OR REPLACE FUNCTION get_shots_with_usernames(p_group_id UUID)
RETURNS TABLE (
    id UUID,
    group_id UUID,
    created_by UUID,
    created_by_username TEXT,
    group_image_url TEXT,
    coffee_weight DECIMAL,
    grinder_setting TEXT,
    extraction_time INTEGER,
    roast_level DECIMAL,
    rating INTEGER,
    extraction_speed TEXT,
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
        g.image_url as group_image_url,
        s.coffee_weight,
        s.grinder_setting,
        s.extraction_time,
        s.roast_level,
        s.rating,
        s.extraction_speed,
        s.notes,
        s.photo_url,
        s.created_at,
        s.updated_at
    FROM public.espresso_shots s
    LEFT JOIN public.profiles p ON s.created_by = p.id
    LEFT JOIN public.coffee_groups g ON s.group_id = g.id
    WHERE s.group_id = p_group_id
    ORDER BY s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
