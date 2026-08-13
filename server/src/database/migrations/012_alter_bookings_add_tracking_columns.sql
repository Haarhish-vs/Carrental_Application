-- 012_alter_bookings_add_tracking_columns.sql
-- Add real-time GPS location tracking columns to bookings table

ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS current_lat DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS current_lng DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS last_tracked_at TIMESTAMPTZ;
