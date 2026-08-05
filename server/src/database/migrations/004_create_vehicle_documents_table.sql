-- 004_create_vehicle_documents_table.sql
CREATE TABLE IF NOT EXISTS public.vehicle_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL CHECK (document_type IN ('rc_book', 'insurance', 'fc')),
    document_url TEXT NOT NULL,
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    rejection_reason TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT now()
);

-- Index for searching documents by vehicle_id
CREATE INDEX IF NOT EXISTS idx_vehicle_docs_vehicle ON public.vehicle_documents(vehicle_id);
