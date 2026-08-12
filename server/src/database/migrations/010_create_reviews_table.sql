-- 010_create_reviews_table.sql
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    renter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    rating NUMERIC NOT NULL CHECK (rating >= 1 AND rating <= 5),
    feedback TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for querying reviews by vehicle
CREATE INDEX IF NOT EXISTS idx_reviews_vehicle ON public.reviews(vehicle_id);

-- Update vehicles table to include rating aggregates (optional but useful for fast queries)
-- Since we calculate it on the fly or just rely on backend counting, it's fine without it.
