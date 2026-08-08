// location.controller.js
const locationService = require('./location.service');

const searchLocations = async (req, res, next) => {
  try {
    const { q } = req.query;
    const locations = await locationService.searchLocations(q);
    
    return res.status(200).json({
      success: true,
      data: locations
    });
  } catch (error) {
    next(error);
  }
};

const reverseGeocode = async (req, res, next) => {
  try {
    const lat = req.query.lat ?? req.query.latitude ?? req.body?.lat ?? req.body?.latitude;
    const lng = req.query.lng ?? req.query.longitude ?? req.body?.lng ?? req.body?.longitude;

    if (lat == null || lng == null) {
      const err = new Error('Latitude and longitude are required');
      err.statusCode = 400;
      throw err;
    }

    const latitude = Number(lat);
    const longitude = Number(lng);

    if (Number.isNaN(latitude) || Number.isNaN(longitude)) {
      const err = new Error('Latitude and longitude must be valid numbers');
      err.statusCode = 400;
      throw err;
    }

    const locationDetails = await locationService.reverseGeocode(latitude, longitude);

    return res.status(200).json({
      success: true,
      data: locationDetails
    });
  } catch (error) {
    next(error);
  }
};

const getPopularLocations = async (req, res, next) => {
  try {
    const popularLocations = await locationService.getPopularLocations();
    
    return res.status(200).json({
      success: true,
      data: popularLocations
    });
  } catch (error) {
    next(error);
  }
};

const getRecentLocations = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const recentLocations = await locationService.getRecentLocations(userId);
    
    return res.status(200).json({
      success: true,
      data: recentLocations
    });
  } catch (error) {
    next(error);
  }
};

const saveRecentLocation = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { placeId, name, address, latitude, longitude, city, state, country } = req.body;

    const lat = Number(latitude);
    const lng = Number(longitude);

    if (Number.isNaN(lat) || Number.isNaN(lng)) {
      const err = new Error('latitude and longitude must be valid numbers');
      err.statusCode = 400;
      throw err;
    }

    const effectivePlaceId = placeId || `pin_${lat}_${lng}`;
    const effectiveName = name || address || 'Selected Location';
    const effectiveAddress = address || name || 'Selected Location';

    const savedLocation = await locationService.saveRecentLocation(userId, {
      placeId: effectivePlaceId,
      name: effectiveName,
      address: effectiveAddress,
      latitude: lat,
      longitude: lng,
      city: city || '',
      state: state || '',
      country: country || '',
    });

    return res.status(201).json({
      success: true,
      message: 'Recent location saved successfully',
      data: savedLocation
    });
  } catch (error) {
    next(error);
  }
};

const deleteRecentLocation = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    
    await locationService.deleteRecentLocation(userId, id);
    
    return res.status(200).json({
      success: true,
      message: 'Recent location deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  searchLocations,
  reverseGeocode,
  getPopularLocations,
  getRecentLocations,
  saveRecentLocation,
  deleteRecentLocation
};