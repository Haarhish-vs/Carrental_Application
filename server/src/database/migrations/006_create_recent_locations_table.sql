-- 006_create_recent_locations_table.sql
CREATE TABLE IF NOT EXISTS public.recent_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    place_id TEXT NOT NULL,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude NUMERIC NOT NULL,
    longitude NUMERIC NOT NULL,
    city TEXT,
    state TEXT,
    country TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fetching a user's recent locations efficiently
CREATE INDEX IF NOT EXISTS idx_recent_locations_user_id ON public.recent_locations(user_id);
