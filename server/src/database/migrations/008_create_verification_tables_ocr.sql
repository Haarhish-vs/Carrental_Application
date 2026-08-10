-- 008_create_verification_tables_ocr.sql
-- Add OCR/status columns to vehicle_documents if they don't exist
ALTER TABLE public.vehicle_documents ADD COLUMN IF NOT EXISTS storage_path TEXT;
ALTER TABLE public.vehicle_documents ADD COLUMN IF NOT EXISTS ocr_text TEXT;
ALTER TABLE public.vehicle_documents ADD COLUMN IF NOT EXISTS extracted_fields JSONB;
ALTER TABLE public.vehicle_documents ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'uploaded';

-- Create verification_reports table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.verification_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    overall_status TEXT NOT NULL,
    overall_score NUMERIC NOT NULL,
    ai_summary TEXT,
    recommendation TEXT,
    validation_results JSONB,
    cross_validation_results JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for searching reports by vehicle_id
CREATE INDEX IF NOT EXISTS idx_verification_reports_vehicle ON public.verification_reports(vehicle_id);
