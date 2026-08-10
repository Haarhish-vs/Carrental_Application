const documentService = require('./document.service');

const uploadDocuments = async (req, res, next) => {
  try {
    console.log('[Upload Endpoint] req.body:', req.body);
    console.log('[Upload Endpoint] req.files:', req.files);

    const { vehicleId } = req.body;

    if (!vehicleId) {
      return res.status(400).json({
        success: false,
        message: `vehicleId is required. Received body: ${JSON.stringify(req.body)}`,
      });
    }

    const result = await documentService.uploadDocuments({ vehicleId, files: req.files || {} });

    return res.status(201).json({
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

    if (!vehicleId) {
      return res.status(400).json({
        success: true,
        message: 'vehicleId is required',
      });
    }

    if (!documentType) {
      return res.status(400).json({
        success: true,
        message: 'documentType is required (rc, insurance, fc, puc, permit)',
      });
    }

    const validTypes = ['rc', 'insurance', 'fc', 'puc', 'permit'];
    if (!validTypes.includes(documentType)) {
      return res.status(422).json({
        success: false,
        message: `Invalid documentType. Must be one of: ${validTypes.join(', ')}`,
      });
    }

    const result = await documentService.analyzeDocument({ vehicleId, documentType });

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

const getVehicleDocuments = async (req, res, next) => {
  try {
    const { vehicleId } = req.params;

    if (!vehicleId) {
      return res.status(400).json({
        success: false,
        message: 'vehicleId is required',
      });
    }

    const result = await documentService.getVehicleDocuments(vehicleId);

    return res.status(200).json({
      success: true,
      message: 'Documents retrieved successfully',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

const getVerificationReport = async (req, res, next) => {
  try {
    const { vehicleId } = req.params;

    if (!vehicleId) {
      return res.status(400).json({
        success: false,
        message: 'vehicleId is required',
      });
    }

    const result = await documentService.getVerificationReport(vehicleId);

    return res.status(200).json({
      success: true,
      message: 'Verification report retrieved successfully',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

const deleteDocument = async (req, res, next) => {
  try {
    const { documentId } = req.params;

    if (!documentId) {
      return res.status(400).json({
        success: false,
        message: 'documentId is required',
      });
    }

    const result = await documentService.deleteDocument(documentId);

    return res.status(200).json({
      success: true,
      message: 'Document deleted successfully',
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
  getVehicleDocuments,
  getVerificationReport,
  deleteDocument,
};
