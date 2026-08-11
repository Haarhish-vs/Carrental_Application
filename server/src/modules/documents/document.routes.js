const express = require('express');
const router = express.Router();
const documentController = require('./document.controller');
const authMiddleware = require('../../shared/middlewares/auth.middleware').protect;
const { uploadDocuments } = require('../../shared/middlewares/upload-documents.middleware');

router.post('/upload', authMiddleware, uploadDocuments, documentController.uploadDocuments);
router.post('/analyze', authMiddleware, documentController.analyzeDocument);
router.post('/verify', authMiddleware, documentController.verifyDocuments);
router.get('/:vehicleId', authMiddleware, documentController.getVehicleDocuments);
router.get('/:vehicleId/report', authMiddleware, documentController.getVerificationReport);
router.delete('/:documentId', authMiddleware, documentController.deleteDocument);

module.exports = router;
