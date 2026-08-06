-- 005_alter_vehicle_documents_constraint.sql
-- Drop the existing check constraint on document_type
ALTER TABLE public.vehicle_documents 
DROP CONSTRAINT IF EXISTS vehicle_documents_document_type_check;

-- Recreate the check constraint to support additional document types
ALTER TABLE public.vehicle_documents 
ADD CONSTRAINT vehicle_documents_document_type_check 
CHECK (document_type IN ('rc_book', 'insurance', 'fc', 'driving_license', 'pollution_certificate'));
