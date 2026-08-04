-- Database Initialization Script for Car Management Module
-- Target: Supabase (PostgreSQL)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables if they exist to allow clean resets
DROP TRIGGER IF EXISTS update_cars_updated_at ON cars;
DROP TRIGGER IF EXISTS update_car_locations_updated_at ON car_locations;
DROP TRIGGER IF EXISTS update_car_pricing_updated_at ON car_pricing;
DROP TRIGGER IF EXISTS update_car_availability_updated_at ON car_availability;
DROP TRIGGER IF EXISTS update_car_documents_updated_at ON car_documents;

DROP TABLE IF EXISTS car_documents CASCADE;
DROP TABLE IF EXISTS car_availability CASCADE;
DROP TABLE IF EXISTS car_pricing CASCADE;
DROP TABLE IF EXISTS car_locations CASCADE;
DROP TABLE IF EXISTS car_images CASCADE;
DROP TABLE IF EXISTS cars CASCADE;

DROP TYPE IF EXISTS car_status CASCADE;

-- Create ENUM for Car Status
CREATE TYPE car_status AS ENUM (
  'DRAFT',
  'PENDING_VERIFICATION',
  'APPROVED',
  'REJECTED',
  'AVAILABLE',
  'BOOKED',
  'MAINTENANCE'
);

-- 1. Cars Table
CREATE TABLE cars (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL,
  brand VARCHAR(100) NOT NULL,
  model VARCHAR(100) NOT NULL,
  variant VARCHAR(100),
  year INTEGER NOT NULL,
  fuel_type VARCHAR(50) NOT NULL,
  transmission VARCHAR(50) NOT NULL,
  mileage NUMERIC NOT NULL,
  engine_capacity INTEGER NOT NULL,
  registration_number VARCHAR(100) UNIQUE NOT NULL,
  status car_status DEFAULT 'DRAFT'::car_status,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Car Images Table
CREATE TABLE car_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  car_id UUID NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  image_type VARCHAR(50) NOT NULL, -- FRONT, BACK, LEFT, RIGHT, INTERIOR, DASHBOARD, OTHER
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Car Locations Table
CREATE TABLE car_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  car_id UUID UNIQUE NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
  pickup_address TEXT NOT NULL,
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100) NOT NULL,
  pincode VARCHAR(20) NOT NULL,
  latitude NUMERIC NOT NULL,
  longitude NUMERIC NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Car Pricing Table
CREATE TABLE car_pricing (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  car_id UUID UNIQUE NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
  price_per_day NUMERIC NOT NULL,
  security_deposit NUMERIC NOT NULL,
  minimum_rental_duration INTEGER NOT NULL,
  instant_booking BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Car Availability Table
CREATE TABLE car_availability (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  car_id UUID UNIQUE NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
  available_dates JSONB DEFAULT '[]'::jsonb, -- Array of date strings: ["2026-08-05", "2026-08-06"]
  blocked_dates JSONB DEFAULT '[]'::jsonb,   -- Array of date strings: ["2026-08-10"]
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Car Documents Table
CREATE TABLE car_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  car_id UUID UNIQUE NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
  rc_url TEXT,
  insurance_url TEXT,
  fitness_url TEXT,
  puc_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Trigger to automatically update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_cars_updated_at BEFORE UPDATE ON cars FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_car_locations_updated_at BEFORE UPDATE ON car_locations FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_car_pricing_updated_at BEFORE UPDATE ON car_pricing FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_car_availability_updated_at BEFORE UPDATE ON car_availability FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_car_documents_updated_at BEFORE UPDATE ON car_documents FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
