-- 013_create_user_fcm_tokens_table.sql
-- Table to store multiple device FCM tokens per user

CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL UNIQUE,
    device_info TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast lookup by user_id
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_fcm_token ON public.user_fcm_tokens(fcm_token);

-- Trigger for automatic updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_user_fcm_tokens_updated_at ON public.user_fcm_tokens;
CREATE TRIGGER trg_update_user_fcm_tokens_updated_at
BEFORE UPDATE ON public.user_fcm_tokens
FOR EACH ROW
EXECUTE FUNCTION update_user_fcm_tokens_updated_at();
