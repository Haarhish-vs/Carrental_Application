-- 007_alter_vehicles_add_state.sql
ALTER TABLE public.vehicles
ADD COLUMN IF NOT EXISTS state TEXT;
