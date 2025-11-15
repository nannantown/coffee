-- Create storage buckets for avatars and group images

-- Create avatars bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Create group-images bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('group-images', 'group-images', true)
ON CONFLICT (id) DO NOTHING;

-- Policy: Allow authenticated users to upload their own avatars
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Allow public read access to avatars
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Policy: Allow users to update their own avatars
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Allow users to delete their own avatars
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Allow authenticated users to upload group images
CREATE POLICY "Authenticated users can upload group images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'group-images');

-- Policy: Allow public read access to group images
CREATE POLICY "Public can view group images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'group-images');

-- Policy: Allow authenticated users to update group images
CREATE POLICY "Authenticated users can update group images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'group-images');

-- Policy: Allow authenticated users to delete group images
CREATE POLICY "Authenticated users can delete group images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'group-images');
