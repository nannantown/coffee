-- Add image support for profiles and groups
-- Profiles: avatar_url for user profile pictures
-- Groups: image_url for group thumbnails

-- Add avatar_url to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Add image_url to coffee_groups table
ALTER TABLE coffee_groups
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Add comments for documentation
COMMENT ON COLUMN profiles.avatar_url IS 'URL to user profile avatar image stored in Supabase Storage';
COMMENT ON COLUMN coffee_groups.image_url IS 'URL to group thumbnail image stored in Supabase Storage';
