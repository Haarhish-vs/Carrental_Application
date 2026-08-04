-- Enable the btree_gist extension to support GIST indexing on scalar types like UUID
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Create placeholder vehicles table if it doesn't exist
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  price_per_day NUMERIC NOT NULL CHECK (price_per_day >= 0),
  deposit_amount NUMERIC NOT NULL DEFAULT 0 CHECK (deposit_amount >= 0),
  status VARCHAR(20) NOT NULL DEFAULT 'under_review' CHECK (status IN ('active', 'under_review', 'suspended')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create profiles table to track cancellation statistics
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  cancellation_count INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id UUID NOT NULL,
  renter_id UUID NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  
  -- Automatically generated date range column combining start_date and end_date (inclusive of both boundaries '[]')
  date_range daterange GENERATED ALWAYS AS (daterange(start_date, end_date, '[]')) STORED,
  
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'active', 'completed', 'cancelled')),
  payment_status VARCHAR(20) NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded')),
  
  total_price NUMERIC NOT NULL CHECK (total_price >= 0),
  deposit_amount NUMERIC NOT NULL CHECK (deposit_amount >= 0),
  
  cancelled_by VARCHAR(20) CHECK (cancelled_by IN ('renter', 'owner', 'system')),
  cancelled_at TIMESTAMPTZ,
  cancellation_reason TEXT,
  cancellation_fee NUMERIC NOT NULL DEFAULT 0 CHECK (cancellation_fee >= 0),
  refund_amount NUMERIC CHECK (refund_amount >= 0),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Foreign Key constraints (assuming vehicles and auth.users exist)
  CONSTRAINT fk_booking_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
  CONSTRAINT fk_booking_renter FOREIGN KEY (renter_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- PostgreSQL EXCLUDE constraint using GIST indexing
  -- This prevents overlapping date ranges for the same vehicle where the booking status is 'pending', 'confirmed', or 'active'
  CONSTRAINT no_overlapping_vehicle_bookings EXCLUDE USING GIST (
    vehicle_id WITH =,
    date_range WITH &&
  ) WHERE (status IN ('pending', 'confirmed', 'active'))
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_bookings_renter_id ON bookings(renter_id);
CREATE INDEX IF NOT EXISTS idx_bookings_vehicle_id ON bookings(vehicle_id);
