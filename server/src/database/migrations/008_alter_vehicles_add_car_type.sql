-- 008_alter_vehicles_add_car_type.sql
-- Adds optional car_type column to vehicles table for classification (SUV, Sedan, Hatchback, MUV, etc.)
ALTER TABLE public.vehicles
ADD COLUMN IF NOT EXISTS car_type TEXT;

-- Index for querying vehicles by car_type
CREATE INDEX IF NOT EXISTS idx_vehicles_car_type ON public.vehicles(car_type);
