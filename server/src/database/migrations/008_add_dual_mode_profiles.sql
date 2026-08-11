-- Dual-mode profile data. One authenticated public.users record can hold
-- both customer and owner capabilities; no duplicate account is created.
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS profile_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS location_address TEXT,
  ADD COLUMN IF NOT EXISTS location_lat NUMERIC,
  ADD COLUMN IF NOT EXISTS location_lng NUMERIC,
  ADD COLUMN IF NOT EXISTS business_name TEXT;

CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('customer', 'owner')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role)
);

-- Existing accounts remain renters; anyone with an existing vehicle is also a host.
INSERT INTO public.user_roles (user_id, role)
SELECT id, 'customer' FROM public.users
ON CONFLICT DO NOTHING;
INSERT INTO public.user_roles (user_id, role)
SELECT DISTINCT owner_id, 'owner' FROM public.vehicles
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS public.user_verification_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  subject_role TEXT NOT NULL DEFAULT 'customer' CHECK (subject_role IN ('customer', 'owner')),
  document_type TEXT NOT NULL,
  document_url TEXT NOT NULL,
  verification_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (verification_status IN ('pending', 'verified', 'expired', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  rater_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  rated_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  rated_role TEXT NOT NULL CHECK (rated_role IN ('customer', 'owner')),
  rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (rater_id <> rated_user_id),
  UNIQUE (booking_id, rater_id)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_target ON public.ratings(rated_user_id, rated_role);
CREATE INDEX IF NOT EXISTS idx_user_verification_documents_user ON public.user_verification_documents(user_id, subject_role);
