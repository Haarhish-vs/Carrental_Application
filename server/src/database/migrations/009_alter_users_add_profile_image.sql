-- 009_alter_users_add_profile_image.sql
-- Add profile_image_url, email, and updated_at to public.users table and public.profiles table

-- 1. Alter public.users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- 2. Alter public.profiles table (if existing)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
        ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
        ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
        ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_number TEXT;
        ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;
        ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_dl_verified BOOLEAN DEFAULT false;
        ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS trust_score NUMERIC DEFAULT 0;
        ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
    END IF;
END $$;
