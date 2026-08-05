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

  async analyzeDocument({ vehicleId, documentType, file }) {
    const detectedType = documentType || ocrService.detectDocumentType(file.originalname);
    const ocrText = await ocrService.extractText(file);

    const record = await documentModel.getLatestDocumentRecord(vehicleId, detectedType);

    if (record) {
      await documentModel.updateDocumentRecord(record.id, {
        ocr_text: ocrText,
        status: 'analyzed',
      });
    }

    return {
      documentType: detectedType,
      ocrText,
      status: 'analyzed',
    };
  }

  async verifyDocuments(vehicleId) {
    const docs = await documentModel.getVehicleDocuments(vehicleId);

    if (!docs.length) {
      throw new Error('No documents found for the provided vehicleId');
    }

    const extractionResults = [];

    for (const doc of docs) {
      const extracted = await ocrService.extractTextFromStoredDocument(doc.public_url);
      extractionResults.push({
        documentType: doc.document_type,
        ocrText: extracted,
      });
    }

    const validationResults = verificationService.validateDocuments(extractionResults);
    const aiAnalysis = await geminiService.analyzeDocuments({
      vehicleId,
      documents: extractionResults,
      validationResults,
    });

    const report = await documentModel.createVerificationReport({
      vehicleId,
      overall_status: aiAnalysis.overallStatus,
      overall_score: aiAnalysis.score,
      ai_summary: aiAnalysis.summary,
      recommendation: aiAnalysis.recommendation,
    });

    return {
      reportId: report.id,
      overallStatus: aiAnalysis.overallStatus,
      overallScore: aiAnalysis.score,
      summary: aiAnalysis.summary,
      recommendations: aiAnalysis.recommendation,
      validationResults,
    };
  }

  getFileExt(fileName) {
    return fileName.includes('.') ? fileName.substring(fileName.lastIndexOf('.')) : '.bin';
  }
}

module.exports = new DocumentService();
