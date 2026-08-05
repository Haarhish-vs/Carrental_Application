const documentService = require('./document.service');

const uploadDocuments = async (req, res, next) => {
  try {
    const { vehicleId } = req.body;

    if (!vehicleId) {
      return res.status(400).json({
        success: false,
        message: 'vehicleId is required',
      });
    }

    const result = await documentService.uploadDocuments({ vehicleId, files: req.files || {} });

    return res.status(200).json({
      success: true,
      message: 'Documents uploaded successfully',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

const analyzeDocument = async (req, res, next) => {
  try {
    const { vehicleId, documentType } = req.body;
    const file = req.files?.[documentType]?.[0] || req.file;

    if (!file) {
      return res.status(400).json({
        success: false,
        message: 'A document file is required',
      });
    }

    const result = await documentService.analyzeDocument({ vehicleId, documentType, file });

    return res.status(200).json({
      success: true,
      message: 'Document analyzed successfully',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

const verifyDocuments = async (req, res, next) => {
  try {
    const { vehicleId } = req.body;

    if (!vehicleId) {
      return res.status(400).json({
        success: false,
        message: 'vehicleId is required',
      });
    }

    const result = await documentService.verifyDocuments(vehicleId);

    return res.status(200).json({
      success: true,
      message: 'Verification completed',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  uploadDocuments,
  analyzeDocument,
  verifyDocuments,
};
