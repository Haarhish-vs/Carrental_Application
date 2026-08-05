const express = require('express');
const router = express.Router();
const documentController = require('./document.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const { uploadDocuments } = require('../../middleware/uploadMiddleware');

router.post('/upload', authMiddleware, uploadDocuments, documentController.uploadDocuments);
router.post('/analyze', authMiddleware, uploadDocuments, documentController.analyzeDocument);
router.post('/verify', authMiddleware, documentController.verifyDocuments);

module.exports = router;
