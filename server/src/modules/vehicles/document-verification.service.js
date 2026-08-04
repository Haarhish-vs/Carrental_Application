// document-verification.service.js
const { supabase } = require('../../config/supabase');

class DocumentVerificationService {
  /**
   * Upload / attach a document to a vehicle.
   * @param {string} vehicleId - Vehicle ID
   * @param {string} userId - Requesting user ID (must be the owner)
   * @param {object} documentData - { documentType, documentUrl }
   */
  async uploadDocument(vehicleId, userId, { documentType, documentUrl }) {
    if (!['rc_book', 'insurance', 'fc'].includes(documentType)) {
      const error = new Error('Invalid document type. Allowed types: rc_book, insurance, fc');
      error.statusCode = 400;
      throw error;
    }

    if (!documentUrl) {
      const error = new Error('Document URL is required');
      error.statusCode = 400;
      throw error;
    }

    // 1. Verify that the vehicle exists and the user is the owner
    const { data: vehicle, error: vehicleError } = await supabase
      .from('vehicles')
      .select('id, owner_id')
      .eq('id', vehicleId)
      .maybeSingle();

    if (vehicleError || !vehicle) {
      const error = new Error('Vehicle not found');
      error.statusCode = 404;
      throw error;
    }

    if (vehicle.owner_id !== userId) {
      const error = new Error('You are not authorized to upload documents for this vehicle');
      error.statusCode = 403;
      throw error;
    }

    // 2. Insert or update the document record
    // We check if a document of this type already exists for the vehicle
    const { data: existingDoc } = await supabase
      .from('vehicle_documents')
      .select('id')
      .eq('vehicle_id', vehicleId)
      .eq('document_type', documentType)
      .maybeSingle();

    let result;
    if (existingDoc) {
      // Update existing document
      const { data, error } = await supabase
        .from('vehicle_documents')
        .update({
          document_url: documentUrl,
          verification_status: 'pending', // reset to pending on re-upload
          rejection_reason: null,
          uploaded_at: new Date().toISOString()
        })
        .eq('id', existingDoc.id)
        .select()
        .single();

      if (error) throw error;
      result = data;
    } else {
      // Create new document entry
      const { data, error } = await supabase
        .from('vehicle_documents')
        .insert({
          vehicle_id: vehicleId,
          document_type: documentType,
          document_url: documentUrl,
          verification_status: 'pending',
          rejection_reason: null
        })
        .select()
        .single();

      if (error) throw error;
      result = data;
    }

    return result;
  }

  /**
   * Admin endpoint placeholder to verify/reject a document.
   * In a production environment, this is where external verification APIs (like Surepass) would be integrated.
   * @param {string} vehicleId - Vehicle ID
   * @param {string} documentType - Document type ('rc_book', 'insurance', 'fc')
   * @param {string} verificationStatus - 'verified' | 'rejected'
   * @param {string} rejectionReason - Optional reason for rejection
   */
  async verifyDocumentAdmin(vehicleId, documentType, verificationStatus, rejectionReason = null) {
    if (!['rc_book', 'insurance', 'fc'].includes(documentType)) {
      const error = new Error('Invalid document type');
      error.statusCode = 400;
      throw error;
    }

    if (!['verified', 'rejected'].includes(verificationStatus)) {
      const error = new Error('Invalid verification status');
      error.statusCode = 400;
      throw error;
    }

    // Find the document record
    const { data: document, error: docError } = await supabase
      .from('vehicle_documents')
      .select('*')
      .eq('vehicle_id', vehicleId)
      .eq('document_type', documentType)
      .maybeSingle();

    if (docError || !document) {
      const error = new Error(`Document of type ${documentType} not found for this vehicle. Owner must upload it first.`);
      error.statusCode = 404;
      throw error;
    }

    // Update document status
    const { data: updatedDoc, error: updateError } = await supabase
      .from('vehicle_documents')
      .update({
        verification_status: verificationStatus,
        rejection_reason: verificationStatus === 'rejected' ? rejectionReason : null
      })
      .eq('id', document.id)
      .select()
      .single();

    if (updateError) throw updateError;

    // Business Logic: If RC Book is verified, transition the vehicle status to active automatically
    if (documentType === 'rc_book' && verificationStatus === 'verified') {
      const { error: vehicleUpdateError } = await supabase
        .from('vehicles')
        .update({ status: 'active' })
        .eq('id', vehicleId);

      if (vehicleUpdateError) {
        throw new Error(`Failed to activate vehicle after RC book verification: ${vehicleUpdateError.message}`);
      }
    } else if (documentType === 'rc_book' && verificationStatus === 'rejected') {
      // If RC Book is rejected, transition the vehicle status to rejected
      await supabase
        .from('vehicles')
        .update({ status: 'rejected' })
        .eq('id', vehicleId);
    }

    return updatedDoc;
  }
}

module.exports = new DocumentVerificationService();
