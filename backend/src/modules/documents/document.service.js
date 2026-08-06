const supabaseStorageService = require('../../services/supabaseStorageService');
const ocrService = require('../../services/ocrService');
const geminiService = require('../../services/geminiService');
const verificationService = require('../../services/verificationService');
const documentModel = require('./document.model');

class DocumentService {
  async uploadDocuments({ vehicleId, files }) {
    const uploaded = [];

    const docFields = ['rc', 'insurance', 'fc', 'puc', 'permit'];

    for (const field of docFields) {
      const file = files?.[field]?.[0];
      if (!file) continue;

      const storagePath = `vehicle-documents/${vehicleId}/${field}${this.getFileExt(file.originalname)}`;
      const publicUrl = await supabaseStorageService.uploadFile({
        bucket: 'vehicle-documents',
        storagePath,
        fileBuffer: file.buffer,
        contentType: file.mimetype,
      });

      const record = await documentModel.upsertDocumentRecord({
        vehicleId,
        documentType: field,
        storagePath,
        publicUrl,
        status: 'uploaded',
      });

      uploaded.push({
        documentType: field,
        storagePath,
        publicUrl,
        recordId: record.id,
      });
    }

    return { uploadedDocuments: uploaded };
  }

  async analyzeDocument({ vehicleId, documentType }) {
    const record = await documentModel.getLatestDocumentRecord(vehicleId, documentType);

    if (!record) {
      const error = new Error(`No uploaded document found for vehicleId: ${vehicleId} and documentType: ${documentType}`);
      error.status = 404;
      throw error;
    }

    if (record.status === 'analyzed') {
      const extractedFields = ocrService.extractFields(record.ocr_text, documentType);
      return {
        documentType,
        ocrText: record.ocr_text,
        extractedFields,
        status: 'analyzed',
        message: 'Document already analyzed',
      };
    }

    const fileBuffer = await supabaseStorageService.downloadFile({
      bucket: 'vehicle-documents',
      storagePath: record.storage_path,
    });

    const ocrText = await ocrService.extractTextFromBuffer(fileBuffer, record.storage_path);

    const extractedFields = ocrService.extractFields(ocrText, documentType);

    await documentModel.updateDocumentRecord(record.id, {
      ocr_text: ocrText,
      extracted_fields: extractedFields,
      status: 'analyzed',
    });

    return {
      documentType,
      ocrText,
      extractedFields,
      status: 'analyzed',
    };
  }

  async verifyDocuments(vehicleId) {
    const docs = await documentModel.getVehicleDocuments(vehicleId);

    if (!docs.length) {
      const error = new Error('No documents found for the provided vehicleId');
      error.status = 404;
      throw error;
    }

    const analyzedDocs = docs.filter(doc => doc.status === 'analyzed');
    if (analyzedDocs.length === 0) {
      const error = new Error('No analyzed documents found. Please analyze documents before verification.');
      error.status = 400;
      throw error;
    }

    const documentData = analyzedDocs.map(doc => ({
      documentType: doc.document_type,
      ocrText: doc.ocr_text,
      extractedFields: doc.extracted_fields || ocrService.extractFields(doc.ocr_text, doc.document_type),
    }));

    const validationResults = verificationService.validateDocuments(documentData);

    const crossValidationResults = verificationService.crossValidateDocuments(documentData);

    const aiAnalysis = await geminiService.analyzeDocuments({
      vehicleId,
      documents: documentData,
      validationResults,
      crossValidationResults,
    });

    await documentModel.updateAllDocumentStatuses(vehicleId, 'verified');

    const report = await documentModel.createVerificationReport({
      vehicleId,
      overall_status: aiAnalysis.overallStatus,
      overall_score: aiAnalysis.score,
      ai_summary: aiAnalysis.summary,
      recommendation: aiAnalysis.recommendation,
      validation_results: validationResults,
      cross_validation_results: crossValidationResults,
    });

    return {
      reportId: report.id,
      overallStatus: aiAnalysis.overallStatus,
      overallScore: aiAnalysis.score,
      summary: aiAnalysis.summary,
      recommendation: aiAnalysis.recommendation,
      validationResults,
      crossValidationResults,
    };
  }

  async getVehicleDocuments(vehicleId) {
    const docs = await documentModel.getVehicleDocuments(vehicleId);

    if (!docs.length) {
      const error = new Error('No documents found for the provided vehicleId');
      error.status = 404;
      throw error;
    }

    return docs;
  }

  async getVerificationReport(vehicleId) {
    const report = await documentModel.getVerificationReport(vehicleId);

    if (!report) {
      const error = new Error('No verification report found for the provided vehicleId');
      error.status = 404;
      throw error;
    }

    return report;
  }

  async deleteDocument(documentId) {
    const record = await documentModel.getDocumentById(documentId);

    if (!record) {
      const error = new Error('Document not found');
      error.status = 404;
      throw error;
    }

    await supabaseStorageService.deleteFile({
      bucket: 'vehicle-documents',
      storagePath: record.storage_path,
    });

    await documentModel.deleteDocumentRecord(documentId);

    return { documentId, message: 'Document deleted successfully' };
  }

  getFileExt(fileName) {
    return fileName.includes('.') ? fileName.substring(fileName.lastIndexOf('.')) : '.bin';
  }
}

module.exports = new DocumentService();
