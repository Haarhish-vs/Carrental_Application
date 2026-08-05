-- 003_create_bookings_table.sql
-- Enable btree_gist extension for combining UUID equality and range overlaps in GIST index
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    renter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    -- Generated column to represent start_date to end_date as an inclusive date range
    date_range daterange GENERATED ALWAYS AS (daterange(start_date, end_date, '[]')) STORED,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'active', 'completed', 'cancelled')),
    payment_status TEXT NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded')),
    total_price NUMERIC NOT NULL,
    deposit_amount NUMERIC NOT NULL DEFAULT 0,
    cancelled_by TEXT CHECK (cancelled_by IN ('renter', 'owner', 'system')),
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    cancellation_fee NUMERIC DEFAULT 0,
    refund_amount NUMERIC,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    -- Exclude constraint to prevent overlapping bookings for the same vehicle
    -- when status is 'pending', 'confirmed', or 'active'
    CONSTRAINT no_overlapping_bookings EXCLUDE USING gist (
        vehicle_id WITH =,
        date_range WITH &&
    ) WHERE (status IN ('pending', 'confirmed', 'active'))
);

-- Index for querying bookings by renter and status
CREATE INDEX IF NOT EXISTS idx_bookings_renter ON public.bookings(renter_id);
-- Index for querying bookings by vehicle
CREATE INDEX IF NOT EXISTS idx_bookings_vehicle ON public.bookings(vehicle_id);
