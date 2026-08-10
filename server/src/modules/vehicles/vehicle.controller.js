// vehicle.controller.js
const jwt = require('jsonwebtoken');
const env = require('../../config/env');
const { supabase } = require('../../config/supabase');
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
    return res.status(500).json({
      success: false,
      message: error.message,
      stack: error.stack
    });
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

const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: env.CLOUDINARY_CLOUD_NAME,
  api_key: env.CLOUDINARY_API_KEY,
  api_secret: env.CLOUDINARY_API_SECRET
});

const uploadMedia = async (req, res, next) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No files uploaded'
      });
    }

    const uploadPromises = req.files.map(file => {
      return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
          { folder: 'vehicles', resource_type: 'auto' },
          (error, result) => {
            if (error) return reject(error);
            resolve(result.secure_url);
          }
        );
        uploadStream.end(file.buffer);
      });
    });

    const urls = await Promise.all(uploadPromises);

    return res.status(200).json({
      success: true,
      message: 'Files uploaded to Cloudinary successfully',
      data: urls
    });
  } catch (error) {
    next(error);
  }
};

const uploadDocumentFile = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No document file uploaded'
      });
    }

    // Ensure the 'documents' bucket exists in Supabase
    const { data: buckets, error: bucketError } = await supabase.storage.listBuckets();
    if (bucketError) {
      return res.status(500).json({
        success: false,
        message: `Failed to list Supabase buckets: ${bucketError.message}`
      });
    }

    const hasBucket = buckets && buckets.some(b => b.name === 'documents');
    if (!hasBucket) {
      const { error: createError } = await supabase.storage.createBucket('documents', {
        public: true
      });
      if (createError) {
        return res.status(500).json({
          success: false,
          message: `Failed to create Supabase documents bucket: ${createError.message}`
        });
      }
    }

    const fileExt = req.file.originalname.split('.').pop();
    const fileName = `doc_${Date.now()}_${Math.round(Math.random() * 1E9)}.${fileExt}`;

    const { data, error } = await supabase.storage
      .from('documents')
      .upload(fileName, req.file.buffer, {
        contentType: req.file.mimetype,
        upsert: true
      });

    if (error) {
      return res.status(500).json({
        success: false,
        message: `Supabase storage upload failed: ${error.message}`
      });
    }

    const { data: { publicUrl } } = supabase.storage
      .from('documents')
      .getPublicUrl(fileName);

    return res.status(200).json({
      success: true,
      message: 'Document uploaded to Supabase storage successfully',
      data: publicUrl
    });
  } catch (error) {
    next(error);
  }
};

const searchVehicles = async (req, res, next) => {
  try {
    const params = req.method === 'GET' ? {
      location: req.query.location ? (typeof req.query.location === 'string' && req.query.location.startsWith('{') ? JSON.parse(req.query.location) : req.query.location) : req.query.city,
      pickupDate: req.query.pickupDate || req.query.pickup_date || req.query.startDate || req.query.start_date,
      pickupTime: req.query.pickupTime || req.query.pickup_time || req.query.startTime || req.query.start_time,
      returnDate: req.query.returnDate || req.query.return_date || req.query.endDate || req.query.end_date,
      returnTime: req.query.returnTime || req.query.return_time || req.query.endTime || req.query.end_time,
      filters: req.query.filters ? (typeof req.query.filters === 'string' ? JSON.parse(req.query.filters) : req.query.filters) : {
        carType: req.query.carType || req.query.car_type,
        transmission: req.query.transmission,
        fuelType: req.query.fuelType || req.query.fuel_type,
        seats: req.query.seats || req.query.seatingCapacity,
        minPrice: req.query.minPrice || req.query.min_price,
        maxPrice: req.query.maxPrice || req.query.max_price
      },
      sort: req.query.sort || req.query.sortBy || 'recommended',
      page: req.query.page || 1,
      limit: req.query.limit || 10
    } : req.body;

    const result = await vehicleService.searchVehicles(params);
    return res.status(200).json(result);
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

const getFilterOptions = async (req, res, next) => {
  try {
    const filters = await vehicleService.getFilterOptions();
    return res.status(200).json({
      success: true,
      filters: filters
    });
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message
      });
    }
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
  verifyDocumentAdmin,
  uploadMedia,
  uploadDocumentFile,
  searchVehicles,
  getFilterOptions
};
