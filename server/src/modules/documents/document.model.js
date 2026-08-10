const { supabase } = require('../../config/supabase');

const TABLE_DOCUMENTS = 'vehicle_documents';
const TABLE_REPORTS = 'verification_reports';

const mapToDbDocType = (docType) => {
  const map = {
    'rc': 'rc_book',
    'rc_book': 'rc_book',
    'insurance': 'insurance',
    'fc': 'fc',
    'puc': 'pollution_certificate',
    'pollution_certificate': 'pollution_certificate',
    'permit': 'fc',
  };
  return map[docType] || docType;
};

const mapFromDbRecord = (record) => {
  if (!record) return record;
  let ocrType = record.document_type;
  if (record.document_type === 'rc_book') {
    ocrType = 'rc';
  } else if (record.document_type === 'pollution_certificate') {
    ocrType = 'puc';
  } else if (record.document_type === 'fc') {
    if (record.storage_path && record.storage_path.includes('/permit')) {
      ocrType = 'permit';
    } else {
      ocrType = 'fc';
    }
  }
  return {
    ...record,
    document_type: ocrType,
  };
};

const upsertDocumentRecord = async ({ vehicleId, documentType, storagePath, publicUrl, ocrText = null, status = 'uploaded', extractedFields = null }) => {
  const { data, error } = await supabase.from(TABLE_DOCUMENTS).insert({
    vehicle_id: vehicleId,
    document_type: mapToDbDocType(documentType),
    storage_path: storagePath,
    public_url: publicUrl,
    document_url: publicUrl,
    ocr_text: ocrText,
    extracted_fields: extractedFields,
    status,
    uploaded_at: new Date().toISOString(),
  }).select().single();

  if (error) throw error;
  return mapFromDbRecord(data);
};

const getLatestDocumentRecord = async (vehicleId, documentType) => {
  const { data, error } = await supabase
    .from(TABLE_DOCUMENTS)
    .select('*')
    .eq('vehicle_id', vehicleId)
    .eq('document_type', mapToDbDocType(documentType))
    .order('uploaded_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  return mapFromDbRecord(data);
};

const getVehicleDocuments = async (vehicleId) => {
  const { data, error } = await supabase
    .from(TABLE_DOCUMENTS)
    .select('*')
    .eq('vehicle_id', vehicleId)
    .order('uploaded_at', { ascending: true });

  if (error) throw error;
  return (data || []).map(mapFromDbRecord);
};

const updateDocumentRecord = async (id, updates) => {
  const { data, error } = await supabase
    .from(TABLE_DOCUMENTS)
    .update(updates)
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return mapFromDbRecord(data);
};

const updateAllDocumentStatuses = async (vehicleId, status) => {
  const { data, error } = await supabase
    .from(TABLE_DOCUMENTS)
    .update({ status, updated_at: new Date().toISOString() })
    .eq('vehicle_id', vehicleId)
    .select();

  if (error) throw error;
  return (data || []).map(mapFromDbRecord);
};

const getDocumentById = async (documentId) => {
  const { data, error } = await supabase
    .from(TABLE_DOCUMENTS)
    .select('*')
    .eq('id', documentId)
    .maybeSingle();

  if (error) throw error;
  return mapFromDbRecord(data);
};

const deleteDocumentRecord = async (documentId) => {
  const { data, error } = await supabase
    .from(TABLE_DOCUMENTS)
    .delete()
    .eq('id', documentId)
    .select()
    .single();

  if (error) throw error;
  return mapFromDbRecord(data);
};

const createVerificationReport = async ({ vehicleId, overall_status, overall_score, ai_summary, recommendation, validation_results = null, cross_validation_results = null }) => {
  const { data, error } = await supabase.from(TABLE_REPORTS).insert({
    vehicle_id: vehicleId,
    overall_status: overall_status,
    overall_score: overall_score,
    ai_summary: ai_summary,
    recommendation,
    validation_results: validation_results,
    cross_validation_results: cross_validation_results,
    created_at: new Date().toISOString(),
  }).select().single();

  if (error) throw error;
  return data;
};

const getVerificationReport = async (vehicleId) => {
  const { data, error } = await supabase
    .from(TABLE_REPORTS)
    .select('*')
    .eq('vehicle_id', vehicleId)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  return data;
};

module.exports = {
  upsertDocumentRecord,
  getLatestDocumentRecord,
  getVehicleDocuments,
  updateDocumentRecord,
  updateAllDocumentStatuses,
  getDocumentById,
  deleteDocumentRecord,
  createVerificationReport,
  getVerificationReport,
};
