// location.service.js
const { supabase } = require('../../config/supabase');
const env = require('../../config/env');

//const GOOGLE_MAPS_API_KEY = env.GOOGLE_MAPS_API_KEY;

/**
 * Searches for a location using OpenStreetMap Nominatim API
 * @param {string} query 
 * @returns {Array} Array of location objects
 */
const searchLocations = async (query) => {
  if (!query) return [];

  const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=jsonv2&addressdetails=1&limit=10`;

  const response = await fetch(url, {
    headers: {
      'User-Agent': 'CarRentalApp/1.0',
      'Accept': 'application/json'
    }
  });

  const data = await response.json();

  if (!Array.isArray(data)) {
    return []; // Return empty array on unexpected response instead of throwing
  }

  return data.map(place => ({
    placeId: place.place_id?.toString() || place.osm_id?.toString() || Math.random().toString(),
    name: place.name || (place.display_name ? place.display_name.split(',')[0] : 'Unknown'),
    address: place.display_name || '',
    latitude: parseFloat(place.lat),
    longitude: parseFloat(place.lon)
  }));
};

/**
 * Reverse geocodes coordinates using OpenStreetMap Nominatim API
 * @param {number} latitude 
 * @param {number} longitude 
 * @returns {Object} Location details (address, city, state, country)
 */
const reverseGeocode = async (latitude, longitude) => {
  if (!latitude || !longitude) {
    throw new Error('Latitude and longitude are required');
  }

  const url = `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=jsonv2&addressdetails=1`;

  const response = await fetch(url, {
    headers: {
      'User-Agent': 'CarRentalApp/1.0',
      'Accept': 'application/json'
    }
  });

  const data = await response.json();

  if (data.error) {
    return null; // Gracefully handle not found or errors
  }

  const address = data.address || {};

  return {
    formattedAddress: data.display_name || '',
    city: address.city || address.town || address.village || address.county || '',
    state: address.state || '',
    country: address.country || ''
  };
};

/**
 * Gets popular locations
 * @returns {Array} List of popular locations
 */
const getPopularLocations = async () => {
  // Hardcoded popular locations as requested
  return [
    { placeId: 'pop_mumbai', name: 'Mumbai', address: 'Mumbai, Maharashtra, India', latitude: 19.0760, longitude: 72.8777, city: 'Mumbai', state: 'Maharashtra' },
    { placeId: 'pop_delhi', name: 'New Delhi', address: 'New Delhi, Delhi, India', latitude: 28.6139, longitude: 77.2090, city: 'New Delhi', state: 'Delhi' },
    { placeId: 'pop_bangalore', name: 'Bengaluru', address: 'Bengaluru, Karnataka, India', latitude: 12.9716, longitude: 77.5946, city: 'Bengaluru', state: 'Karnataka' },
    { placeId: 'pop_hyderabad', name: 'Hyderabad', address: 'Hyderabad, Telangana, India', latitude: 17.3850, longitude: 78.4867, city: 'Hyderabad', state: 'Telangana' },
    { placeId: 'pop_chennai', name: 'Chennai', address: 'Chennai, Tamil Nadu, India', latitude: 13.0827, longitude: 80.2707, city: 'Chennai', state: 'Tamil Nadu' }
  ];
};

/**
 * Gets recent locations for an authenticated user
 * @param {string} userId 
 * @returns {Array} List of recent locations
 */
const getRecentLocations = async (userId) => {
  const { data, error } = await supabase
    .from('recent_locations')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(10);

  if (error) {
    throw new Error(`Failed to fetch recent locations: ${error.message}`);
  }

  return data;
};

/**
 * Saves a recent location for a user, avoiding duplicates and keeping max 10 records.
 * @param {string} userId 
 * @param {Object} locationData 
 * @returns {Object} Saved location
 */
const saveRecentLocation = async (userId, locationData) => {
  const { placeId, name, address, latitude, longitude, city, state, country } = locationData;

  // First, check if this place already exists in the user's recent list
  const { data: existingRecords, error: existingError } = await supabase
    .from('recent_locations')
    .select('id')
    .eq('user_id', userId)
    .eq('place_id', placeId);

  if (existingError) {
    throw new Error(`Error checking existing location: ${existingError.message}`);
  }

  // If it exists, delete it so the new insert pushes it to the top of 'recent'
  if (existingRecords && existingRecords.length > 0) {
    const { error: deleteExistingError } = await supabase
      .from('recent_locations')
      .delete()
      .eq('id', existingRecords[0].id);

    if (deleteExistingError) {
      throw new Error(`Error removing duplicate recent location: ${deleteExistingError.message}`);
    }
  } else {
    // If it doesn't exist, we might need to prune older entries if they have >= 10
    const { data: allUserLocations, error: countError } = await supabase
      .from('recent_locations')
      .select('id')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (countError) {
      throw new Error(`Error counting user locations: ${countError.message}`);
    }

    if (allUserLocations && allUserLocations.length >= 10) {
      // Delete the oldest ones to make space for the new one (keep 9 newest)
      const idsToDelete = allUserLocations.slice(9).map(loc => loc.id);

      const { error: pruneError } = await supabase
        .from('recent_locations')
        .delete()
        .in('id', idsToDelete);

      if (pruneError) {
        throw new Error(`Error pruning old locations: ${pruneError.message}`);
      }
    }
  }

  // Insert the new location
  const { data: newLocation, error: insertError } = await supabase
    .from('recent_locations')
    .insert([{
      user_id: userId,
      place_id: placeId,
      name,
      address,
      latitude,
      longitude,
      city,
      state,
      country
    }])
    .select()
    .single();

  if (insertError) {
    throw new Error(`Failed to save recent location: ${insertError.message}`);
  }

  return newLocation;
};

/**
 * Deletes a recent location by ID for a specific user
 * @param {string} userId 
 * @param {string} locationId 
 */
const deleteRecentLocation = async (userId, locationId) => {
  const { error } = await supabase
    .from('recent_locations')
    .delete()
    .eq('id', locationId)
    .eq('user_id', userId);

  if (error) {
    throw new Error(`Failed to delete recent location: ${error.message}`);
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
