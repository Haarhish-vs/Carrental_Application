-- 001_create_profiles_table.sql
-- Create extension for UUID generation if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create public.users table extending auth.users
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number TEXT UNIQUE NOT NULL,
    full_name TEXT,
    is_dl_verified BOOLEAN DEFAULT false,
    trust_score NUMERIC DEFAULT 0,
    cancellation_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create public.otp_verifications table for SMS OTP flow
CREATE TABLE IF NOT EXISTS public.otp_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT NOT NULL,
    otp_code TEXT NOT NULL, -- Hashed OTP code using bcrypt
    expires_at TIMESTAMPTZ NOT NULL,
    is_verified BOOLEAN DEFAULT false,
    attempts INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast OTP lookup by phone number
CREATE INDEX IF NOT EXISTS idx_otp_phone ON public.otp_verifications(phone_number);
