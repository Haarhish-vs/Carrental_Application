// vehicle.controller.js
const jwt = require('jsonwebtoken');
const env = require('../../config/env');
const vehicleService = require('./vehicle.service');
const docVerificationService = require('./document-verification.service');

const getVehicles = async (req, res, next) => {
  try {
    const filters = req.query;
    const vehicles = await vehicleService.getVehicles(filters);
    return res.status(200).json({
      success: true,
      data: vehicles
    });
  } catch (error) {
    next(error);
  }
};

const getVehicleById = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    // Optional Auth: Try to decode token if provided to check if phone number should be visible
    let currentUserId = null;
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const decoded = jwt.verify(token, env.JWT_SECRET);
        currentUserId = decoded.sub;
      } catch (err) {
        // Ignore token verification errors for public listing details
      }
    }

    const vehicle = await vehicleService.getVehicleById(id, currentUserId);
    return res.status(200).json({
      success: true,
      data: vehicle
    });
  } catch (error) {
    next(error);
  }
};

const createVehicle = async (req, res, next) => {
  try {
    const vehicle = await vehicleService.createVehicle(req.user.id, req.body);
    return res.status(201).json({
      success: true,
      message: 'Vehicle listing created successfully. Under review.',
      data: vehicle
    });
  } catch (error) {
    next(error);
  }
};

const uploadDocument = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { documentType, documentUrl } = req.body;
    const document = await docVerificationService.uploadDocument(id, req.user.id, { documentType, documentUrl });
    return res.status(201).json({
      success: true,
      message: 'Document uploaded successfully. Verification pending.',
      data: document
    });
  } catch (error) {
    next(error);
  }
};

const updateVehicle = async (req, res, next) => {
  try {
    const { id } = req.params;
    const vehicle = await vehicleService.updateVehicle(id, req.user.id, req.body);
    return res.status(200).json({
      success: true,
      message: 'Vehicle listing updated successfully',
      data: vehicle
    });
  } catch (error) {
    next(error);
  }
};

const toggleAvailability = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { isAvailable } = req.body;
    const vehicle = await vehicleService.toggleAvailability(id, req.user.id, isAvailable);
    return res.status(200).json({
      success: true,
      message: `Vehicle availability set to ${isAvailable}`,
      data: vehicle
    });
  } catch (error) {
    next(error);
  }
};

const getMyListings = async (req, res, next) => {
  try {
    const listings = await vehicleService.getMyListings(req.user.id);
    return res.status(200).json({
      success: true,
      data: listings
    });
  } catch (error) {
    next(error);
  }
};

const deleteVehicle = async (req, res, next) => {
  try {
    const { id } = req.params;
    await vehicleService.deleteVehicle(id, req.user.id);
    return res.status(200).json({
      success: true,
      message: 'Vehicle listing deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Admin Simulation Endpoint
const verifyDocumentAdmin = async (req, res, next) => {
  try {
    const { id } = req.params; // vehicleId
    const { documentType, verificationStatus, rejectionReason } = req.body;
    const document = await docVerificationService.verifyDocumentAdmin(id, documentType, verificationStatus, rejectionReason);
    return res.status(200).json({
      success: true,
      message: `Document of type ${documentType} has been ${verificationStatus}`,
      data: document
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getVehicles,
  getVehicleById,
  createVehicle,
  uploadDocument,
  updateVehicle,
  toggleAvailability,
  getMyListings,
  deleteVehicle,
  verifyDocumentAdmin
};
