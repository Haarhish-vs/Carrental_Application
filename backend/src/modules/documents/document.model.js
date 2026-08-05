const { supabase } = require('../../config/supabaseClient');

const TABLE_DOCUMENTS = 'vehicle_documents';
const TABLE_REPORTS = 'verification_reports';

const upsertDocumentRecord = async ({ vehicleId, documentType, storagePath, publicUrl, ocrText = null, status = 'uploaded' }) => {
  const { data, error } = await supabase.from(TABLE_DOCUMENTS).insert({
    vehicle_id: vehicleId,
    document_type: documentType,
    storage_path: storagePath,
    public_url: publicUrl,
    ocr_text: ocrText,
    status,
    uploaded_at: new Date().toISOString(),
  }).select().single();

  if (error) throw error;
  return data;
};

const getLatestDocumentRecord = async (vehicleId, documentType) => {
  const { data, error } = await supabase
    .from(TABLE_DOCUMENTS)
    .select('*')
    .eq('vehicle_id', vehicleId)
    .eq('document_type', documentType)
    .order('uploaded_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  return data;
};

const getVehicleDocuments = async (vehicleId) => {
  const { data, error } = await supabase
    .from(TABLE_DOCUMENTS)
    .select('*')
    .eq('vehicle_id', vehicleId)
    .order('uploaded_at', { ascending: true });

  if (error) throw error;
  return data || [];
};

const updateDocumentRecord = async (id, updates) => {
  const { data, error } = await supabase
    .from(TABLE_DOCUMENTS)
    .update(updates)
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return data;
};

const createVerificationReport = async ({ vehicleId, overall_status, overall_score, ai_summary, recommendation }) => {
  const { data, error } = await supabase.from(TABLE_REPORTS).insert({
    vehicle_id: vehicleId,
    overall_status: overall_status,
    overall_score: overall_score,
    ai_summary: ai_summary,
    recommendation,
    created_at: new Date().toISOString(),
  }).select().single();

  if (error) throw error;
  return data;
};

module.exports = {
  upsertDocumentRecord,
  getLatestDocumentRecord,
  getVehicleDocuments,
  updateDocumentRecord,
  createVerificationReport,
};
