-- 011_alter_bookings_dates_to_timestamps.sql
-- Modify bookings table to store exact exact timezone-aware timestamps instead of just dates.
-- This allows precise tracking of pickup and drop-off times.

-- 1. Drop the existing exclusion constraint that relies on date ranges
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS no_overlapping_bookings;

-- 2. Drop the generated date_range column
ALTER TABLE public.bookings DROP COLUMN IF EXISTS date_range;

-- 3. Change start_date and end_date from DATE to TIMESTAMPTZ
ALTER TABLE public.bookings ALTER COLUMN start_date TYPE TIMESTAMPTZ USING start_date::TIMESTAMPTZ;
ALTER TABLE public.bookings ALTER COLUMN end_date TYPE TIMESTAMPTZ USING end_date::TIMESTAMPTZ;

-- 4. Create a new generated time_range column using tstzrange
ALTER TABLE public.bookings ADD COLUMN time_range tstzrange GENERATED ALWAYS AS (tstzrange(start_date, end_date, '[]')) STORED;

-- 5. Add the exclusion constraint back, this time using time_range (tstzrange)
-- This ensures that bookings cannot overlap exactly in time.
ALTER TABLE public.bookings ADD CONSTRAINT no_overlapping_bookings EXCLUDE USING gist (
    vehicle_id WITH =,
    time_range WITH &&
) WHERE (status IN ('pending', 'confirmed', 'active'));
