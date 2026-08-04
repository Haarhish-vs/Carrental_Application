-- 002_create_vehicles_table.sql
CREATE TABLE IF NOT EXISTS public.vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    variant TEXT,
    manufacturing_year INT,
    registration_number TEXT,
    fuel_type TEXT NOT NULL,
    transmission TEXT NOT NULL,
    mileage NUMERIC,
    seats INT NOT NULL, -- seating capacity
    color TEXT,
    engine_capacity TEXT,
    odometer_reading NUMERIC,
    vehicle_description TEXT,
    price_per_day NUMERIC NOT NULL, -- daily price
    deposit_amount NUMERIC DEFAULT 0, -- security deposit
    minimum_rental_days INT DEFAULT 1,
    pickup_location TEXT,
    availability_from TIMESTAMPTZ,
    availability_to TIMESTAMPTZ,
    delivery_fee NUMERIC DEFAULT 0,
    images TEXT[] DEFAULT '{}', -- selected photos
    rc_number TEXT NOT NULL,
    location_lat NUMERIC,
    location_lng NUMERIC,
    city TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'under_review' CHECK (status IN ('under_review', 'active', 'suspended', 'rejected')),
    is_available BOOLEAN DEFAULT true,
    fc_expiry DATE,
    insurance_expiry DATE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index for searching vehicles by city and status
CREATE INDEX IF NOT EXISTS idx_vehicles_city_status ON public.vehicles(city, status);
