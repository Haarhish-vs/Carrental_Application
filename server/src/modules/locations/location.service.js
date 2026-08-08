// location.service.js

const { supabase } = require('../../config/supabase');
const env = require('../../config/env');

const GOOGLE_MAPS_API_KEY = env.GOOGLE_MAPS_API_KEY;

if (!GOOGLE_MAPS_API_KEY) {
  console.warn(
    '⚠️ GOOGLE_MAPS_API_KEY is not set. Location search/reverse-geocode will fail.'
  );
}

// -----------------------------------------------------------------------------
// Google API configuration
// -----------------------------------------------------------------------------

const GOOGLE_AUTOCOMPLETE_URL =
  'https://places.googleapis.com/v1/places:autocomplete';

const GOOGLE_PLACE_DETAILS_URL =
  'https://places.googleapis.com/v1/places';

const GOOGLE_REVERSE_GEOCODE_URL =
  'https://geocode.googleapis.com/v4/geocode/location';

const REQUEST_TIMEOUT_MS = 8000;

// Number of autocomplete results returned to Flutter.
const MAX_SEARCH_RESULTS = 5;

// -----------------------------------------------------------------------------
// HTTP helper
// -----------------------------------------------------------------------------

/**
 * Wraps fetch with a timeout so a hanging Google API call
 * cannot hang the request.
 *
 * @param {string} url
 * @param {Object} options
 * @returns {Promise<Response>}
 */
const fetchWithTimeout = async (url, options = {}) => {
  const controller = new AbortController();

  const timeoutId = setTimeout(() => {
    controller.abort();
  }, REQUEST_TIMEOUT_MS);

  try {
    return await fetch(url, {
      ...options,
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeoutId);
  }
};

// -----------------------------------------------------------------------------
// Google error handling
// -----------------------------------------------------------------------------

/**
 * Extracts a useful Google API error message.
 *
 * @param {Object} data
 * @returns {string}
 */
const getGoogleErrorMessage = (data) => {
  if (!data) {
    return '';
  }

  if (typeof data.error === 'string') {
    return data.error;
  }

  if (data.error?.message) {
    return data.error.message;
  }

  if (data.error?.status) {
    return data.error.status;
  }

  if (data.error_message) {
    return data.error_message;
  }

  return '';
};

/**
 * Handles Google Places / Geocoding HTTP errors.
 *
 * @param {number} httpStatus
 * @param {Object} data
 * @param {string} operation
 */
const handleGoogleError = (httpStatus, data, operation) => {
  const errorStatus = data?.error?.status;
  const errorMessage = getGoogleErrorMessage(data);

  console.error(
    `Google ${operation} failed. HTTP ${httpStatus}. ` +
    `${errorStatus || ''} ${errorMessage || ''}`.trim()
  );

  switch (errorStatus) {
    case 'RESOURCE_EXHAUSTED':
      throw new Error(
        'Location service quota exceeded for today. Please try again later.'
      );

    case 'PERMISSION_DENIED':
      throw new Error(
        'Location service is misconfigured. Please check the Google Maps API key.'
      );

    case 'INVALID_ARGUMENT':
      throw new Error(
        'Invalid location request. Please check the search input.'
      );

    case 'NOT_FOUND':
      return;

    default:
      if (httpStatus === 429) {
        throw new Error(
          'Location service quota exceeded for today. Please try again later.'
        );
      }

      if (httpStatus === 401 || httpStatus === 403) {
        throw new Error(
          'Location service is misconfigured. Please check the Google Maps API key.'
        );
      }

      throw new Error(
        `Google ${operation} failed. Please try again later.`
      );
  }
};

// -----------------------------------------------------------------------------
// Address component helper
// -----------------------------------------------------------------------------

/**
 * Extracts a specific address component from Google Places/Geocoding results.
 *
 * Google Places API (New) and Geocoding API v4 use:
 *
 *   addressComponents[].longText
 *   addressComponents[].types
 *
 * Older Google APIs used:
 *
 *   address_components[].long_name
 *   address_components[].types
 *
 * This helper supports both structures.
 *
 * @param {Object} result
 * @param {string} type
 * @returns {string}
 */
const getAddressComponent = (result, type) => {
  const components =
    result?.addressComponents ||
    result?.address_components ||
    [];

  const component = components.find((item) =>
    Array.isArray(item.types) && item.types.includes(type)
  );

  if (!component) {
    return '';
  }

  return (
    component.longText ||
    component.long_name ||
    component.shortText ||
    component.short_name ||
    ''
  );
};

// -----------------------------------------------------------------------------
// Location mapping
// -----------------------------------------------------------------------------

/**
 * Gets the best available city from Google address components.
 *
 * @param {Object} result
 * @returns {string}
 */
const getCityFromResult = (result) => {
  return (
    getAddressComponent(result, 'locality') ||
    getAddressComponent(result, 'administrative_area_level_2') ||
    getAddressComponent(result, 'administrative_area_level_3') ||
    getAddressComponent(result, 'sublocality') ||
    getAddressComponent(result, 'postal_town') ||
    ''
  );
};

/**
 * Gets state from Google address components.
 *
 * @param {Object} result
 * @returns {string}
 */
const getStateFromResult = (result) => {
  return (
    getAddressComponent(result, 'administrative_area_level_1') ||
    ''
  );
};

/**
 * Gets country from Google address components.
 *
 * @param {Object} result
 * @returns {string}
 */
const getCountryFromResult = (result) => {
  return getAddressComponent(result, 'country') || '';
};

/**
 * Maps a Google Place Details / Geocoding v4 result
 * to the application's standard LocationModel response shape.
 *
 * Response shape:
 * {
 *   id,
 *   placeId,
 *   name,
 *   address,
 *   latitude,
 *   longitude,
 *   city,
 *   state,
 *   country
 * }
 *
 * @param {Object} result
 * @param {string} fallbackName
 * @returns {Object}
 */
const mapGoogleResult = (result, fallbackName = '') => {
  const location = result?.location || {};

  const latitude =
    typeof location.latitude === 'number'
      ? location.latitude
      : typeof location.lat === 'number'
        ? location.lat
        : parseFloat(location.latitude ?? location.lat);

  const longitude =
    typeof location.longitude === 'number'
      ? location.longitude
      : typeof location.lng === 'number'
        ? location.lng
        : parseFloat(location.longitude ?? location.lng);

  const placeId =
    result?.placeId ||
    result?.id ||
    '';

  const address =
    result?.formattedAddress ||
    result?.shortFormattedAddress ||
    '';

  const city = getCityFromResult(result);
  const state = getStateFromResult(result);
  const country = getCountryFromResult(result);

  const name =
    fallbackName ||
    city ||
    result?.displayName?.text ||
    result?.postalAddress?.locality ||
    address.split(',')[0] ||
    'Unknown';

  return {
    id: null,

    placeId,

    name,

    address,

    latitude,

    longitude,

    city,

    state,

    country,
  };
};

// -----------------------------------------------------------------------------
// Places API (New) - Autocomplete
// -----------------------------------------------------------------------------

/**
 * Searches for location suggestions using Google Places API (New)
 * Autocomplete.
 *
 * Example:
 *
 *   "c"
 *
 * can return suggestions such as:
 *
 *   Chennai
 *   Coimbatore
 *   Chandigarh
 *
 * We use "(cities)" because this application is selecting
 * rental locations/cities rather than restaurants or businesses.
 *
 * @param {string} query
 * @param {string|null} sessionToken
 * @returns {Array}
 */
const searchLocations = async (query, sessionToken = null) => {
  if (!query || !query.trim()) {
    return [];
  }

  if (!GOOGLE_MAPS_API_KEY) {
    throw new Error(
      'Location service is not configured. Google Maps API key is missing.'
    );
  }

  const trimmedQuery = query.trim();

  const requestBody = {
    input: trimmedQuery,

    // Restrict autocomplete to city-level results.
    includedPrimaryTypes: ['(cities)'],

    // Restrict results to India.
    includedRegionCodes: ['in'],

    // Prefer English responses.
    languageCode: 'en',

    // Format/rank results for India.
    regionCode: 'IN',

    // Do not return query predictions.
    includeQueryPredictions: false,
  };

  // Session token is optional.
  //
  // If your Flutter frontend already creates a session token,
  // it can be passed to this method as the second argument.
  if (sessionToken) {
    requestBody.sessionToken = sessionToken;
  }

  let response;

  try {
    response = await fetchWithTimeout(GOOGLE_AUTOCOMPLETE_URL, {
      method: 'POST',

      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': GOOGLE_MAPS_API_KEY,
      },

      body: JSON.stringify(requestBody),
    });
  } catch (fetchError) {
    console.error(
      `Location autocomplete request failed: ${fetchError.message}`
    );

    throw new Error(
      'Failed to reach the location service. Please try again.'
    );
  }

  let data;

  try {
    data = await response.json();
  } catch (parseError) {
    console.error(
      `Location autocomplete returned invalid JSON: ${parseError.message}`
    );

    throw new Error(
      'Location service returned an invalid response.'
    );
  }

  if (!response.ok) {
    handleGoogleError(
      response.status,
      data,
      'Places Autocomplete'
    );

    return [];
  }

  const suggestions = Array.isArray(data?.suggestions)
    ? data.suggestions
    : [];

  const placePredictions = suggestions
    .filter(
      (suggestion) =>
        suggestion?.placePrediction?.placeId
    )
    .slice(0, MAX_SEARCH_RESULTS);

  if (placePredictions.length === 0) {
    return [];
  }

  // ---------------------------------------------------------------------------
  // Autocomplete returns place IDs but not the complete location object.
  //
  // Therefore, retrieve Place Details (New) for each prediction so that
  // LocationModel receives:
  //
  // placeId
  // name
  // address
  // latitude
  // longitude
  // city
  // state
  // country
  // ---------------------------------------------------------------------------

  const locations = await Promise.all(
    placePredictions.map(async (suggestion) => {
      const prediction = suggestion.placePrediction;

      const placeId = prediction.placeId;

      const fallbackName =
        prediction.structuredFormat?.mainText?.text ||
        prediction.text?.text ||
        'Unknown';

      try {
        const place = await getPlaceDetails(
          placeId,
          sessionToken
        );

        if (!place) {
          return null;
        }

        return mapGoogleResult(place, fallbackName);
      } catch (error) {
        console.error(
          `Failed to get details for place ${placeId}: ${error.message}`
        );

        return null;
      }
    })
  );

  return locations.filter(Boolean);
};

// -----------------------------------------------------------------------------
// Places API (New) - Place Details
// -----------------------------------------------------------------------------

/**
 * Gets Place Details using Google Places API (New).
 *
 * Only fields required by LocationModel are requested.
 *
 * @param {string} placeId
 * @param {string|null} sessionToken
 * @returns {Object|null}
 */
const getPlaceDetails = async (
  placeId,
  sessionToken = null
) => {
  if (!placeId) {
    return null;
  }

  if (!GOOGLE_MAPS_API_KEY) {
    throw new Error(
      'Location service is not configured. Google Maps API key is missing.'
    );
  }

  const url =
    `${GOOGLE_PLACE_DETAILS_URL}/` +
    `${encodeURIComponent(placeId)}` +
    `?regionCode=IN&languageCode=en`;

  const headers = {
    'Content-Type': 'application/json',

    'X-Goog-Api-Key': GOOGLE_MAPS_API_KEY,

    // Only request fields required by LocationModel.
    //
    // displayName is intentionally not requested because the
    // autocomplete prediction already gives us the user-facing name.
    'X-Goog-FieldMask':
      'id,formattedAddress,shortFormattedAddress,location,addressComponents,types',
  };

  // If the frontend supplies a session token, pass it through
  // to the Place Details request.
  if (sessionToken) {
    headers['X-Goog-Session-Token'] = sessionToken;
  }

  let response;

  try {
    response = await fetchWithTimeout(url, {
      method: 'GET',
      headers,
    });
  } catch (fetchError) {
    console.error(
      `Place details request failed: ${fetchError.message}`
    );

    throw new Error(
      'Failed to reach the location service. Please try again.'
    );
  }

  let data;

  try {
    data = await response.json();
  } catch (parseError) {
    console.error(
      `Place details returned invalid JSON: ${parseError.message}`
    );

    throw new Error(
      'Location service returned an invalid response.'
    );
  }

  if (!response.ok) {
    handleGoogleError(
      response.status,
      data,
      'Place Details'
    );

    return null;
  }

  return data;
};

// -----------------------------------------------------------------------------
// Geocoding API v4 - Reverse Geocoding
// -----------------------------------------------------------------------------

/**
 * Reverse geocodes coordinates using Google Geocoding API v4.
 *
 * Converts:
 *
 *   latitude + longitude
 *
 * into:
 *
 *   human-readable address
 *
 * @param {number} latitude
 * @param {number} longitude
 * @returns {Object|null}
 */
const reverseGeocode = async (latitude, longitude) => {
  if (
    latitude == null ||
    longitude == null ||
    Number.isNaN(Number(latitude)) ||
    Number.isNaN(Number(longitude))
  ) {
    throw new Error(
      'Latitude and longitude are required'
    );
  }

  if (!GOOGLE_MAPS_API_KEY) {
    throw new Error(
      'Location service is not configured. Google Maps API key is missing.'
    );
  }

  const lat = Number(latitude);
  const lng = Number(longitude);

  if (lat < -90 || lat > 90) {
    throw new Error(
      'Latitude must be between -90 and 90.'
    );
  }

  if (lng < -180 || lng > 180) {
    throw new Error(
      'Longitude must be between -180 and 180.'
    );
  }

  // Google Geocoding API v4 reverse-geocoding endpoint.
  //
  // Example:
  //
  // https://geocode.googleapis.com/v4/geocode/location/13.0827,80.2707
  //
  const url =
    `${GOOGLE_REVERSE_GEOCODE_URL}/` +
    `${encodeURIComponent(`${lat},${lng}`)}` +
    `?regionCode=IN&languageCode=en`;

  let response;

  try {
    response = await fetchWithTimeout(url, {
      method: 'GET',

      headers: {
        'Content-Type': 'application/json',

        'X-Goog-Api-Key': GOOGLE_MAPS_API_KEY,

        // Only request fields needed by LocationModel.
        'X-Goog-FieldMask':
          'results.placeId,results.location,results.formattedAddress,results.addressComponents',
      },
    });
  } catch (fetchError) {
    console.error(
      `Reverse geocode request failed: ${fetchError.message}`
    );

    throw new Error(
      'Failed to reach the location service. Please try again.'
    );
  }

  let data;

  try {
    data = await response.json();
  } catch (parseError) {
    console.error(
      `Reverse geocode returned invalid JSON: ${parseError.message}`
    );

    throw new Error(
      'Location service returned an invalid response.'
    );
  }

  if (!response.ok) {
    handleGoogleError(
      response.status,
      data,
      'Geocoding'
    );

    return null;
  }

  const results = Array.isArray(data?.results)
    ? data.results
    : [];

  if (results.length === 0) {
    return null;
  }

  // Google may return several results for the same coordinate.
  //
  // The first result is normally the closest/most relevant
  // human-readable address.
  const result = results[0];

  return {
    id: null,

    placeId: result.placeId || '',

    name:
      getCityFromResult(result) ||
      result.formattedAddress?.split(',')[0] ||
      'Unknown',

    address: result.formattedAddress || '',

    latitude: Number(latitude),

    longitude: Number(longitude),

    city: getCityFromResult(result),

    state: getStateFromResult(result),

    country: getCountryFromResult(result),
  };
};

// -----------------------------------------------------------------------------
// Popular Locations
// -----------------------------------------------------------------------------

/**
 * Gets popular locations.
 *
 * These are hardcoded popular Indian cities.
 *
 * @returns {Array}
 */
const getPopularLocations = async () => {
  return [
    {
      id: null,
      placeId: 'pop_mumbai',
      name: 'Mumbai',
      address: 'Mumbai, Maharashtra, India',
      latitude: 19.0760,
      longitude: 72.8777,
      city: 'Mumbai',
      state: 'Maharashtra',
      country: 'India',
    },

    {
      id: null,
      placeId: 'pop_delhi',
      name: 'New Delhi',
      address: 'New Delhi, Delhi, India',
      latitude: 28.6139,
      longitude: 77.2090,
      city: 'New Delhi',
      state: 'Delhi',
      country: 'India',
    },

    {
      id: null,
      placeId: 'pop_bangalore',
      name: 'Bengaluru',
      address: 'Bengaluru, Karnataka, India',
      latitude: 12.9716,
      longitude: 77.5946,
      city: 'Bengaluru',
      state: 'Karnataka',
      country: 'India',
    },

    {
      id: null,
      placeId: 'pop_hyderabad',
      name: 'Hyderabad',
      address: 'Hyderabad, Telangana, India',
      latitude: 17.3850,
      longitude: 78.4867,
      city: 'Hyderabad',
      state: 'Telangana',
      country: 'India',
    },

    {
      id: null,
      placeId: 'pop_chennai',
      name: 'Chennai',
      address: 'Chennai, Tamil Nadu, India',
      latitude: 13.0827,
      longitude: 80.2707,
      city: 'Chennai',
      state: 'Tamil Nadu',
      country: 'India',
    },
  ];
};

// -----------------------------------------------------------------------------
// Recent Locations - Supabase
// -----------------------------------------------------------------------------

/**
 * Gets recent locations for an authenticated user.
 *
 * @param {string} userId
 * @returns {Array}
 */
const getRecentLocations = async (userId) => {
  if (!userId) {
    throw new Error('User ID is required');
  }

  const { data, error } = await supabase
    .from('recent_locations')
    .select(
      'id, place_id, name, address, latitude, longitude, city, state, country'
    )
    .eq('user_id', userId)
    .order('created_at', {
      ascending: false,
    })
    .limit(10);

  if (error) {
    throw new Error(
      `Failed to fetch recent locations: ${error.message}`
    );
  }

  /**
   * Convert database snake_case fields into the same
   * camelCase structure expected by Flutter LocationModel.
   */
  return (data || []).map((location) => ({
    id: location.id,

    placeId: location.place_id,

    name: location.name,

    address: location.address,

    latitude: Number(location.latitude),

    longitude: Number(location.longitude),

    city: location.city || '',

    state: location.state || '',

    country: location.country || '',
  }));
};

// -----------------------------------------------------------------------------
// Save Recent Location
// -----------------------------------------------------------------------------

/**
 * Saves a recent location for a user.
 *
 * Avoids duplicates and keeps a maximum of 10 locations.
 *
 * @param {string} userId
 * @param {Object} locationData
 * @returns {Object}
 */
const saveRecentLocation = async (
  userId,
  locationData
) => {
  if (!userId) {
    throw new Error('User ID is required');
  }

  if (!locationData) {
    throw new Error('Location data is required');
  }

  const {
    placeId,
    name,
    address,
    latitude,
    longitude,
    city,
    state,
    country,
  } = locationData;

  if (
    !placeId ||
    !name ||
    !address ||
    latitude == null ||
    longitude == null
  ) {
    throw new Error(
      'Invalid location data'
    );
  }

  // Check whether this location already exists.
  const {
    data: existingRecords,
    error: existingError,
  } = await supabase
    .from('recent_locations')
    .select('id')
    .eq('user_id', userId)
    .eq('place_id', placeId);

  if (existingError) {
    throw new Error(
      `Error checking existing location: ${existingError.message}`
    );
  }

  // If it exists, delete it so the new insert
  // moves it to the top of the recent list.
  if (
    existingRecords &&
    existingRecords.length > 0
  ) {
    const {
      error: deleteExistingError,
    } = await supabase
      .from('recent_locations')
      .delete()
      .eq(
        'id',
        existingRecords[0].id
      );

    if (deleteExistingError) {
      throw new Error(
        `Error removing duplicate recent location: ${deleteExistingError.message}`
      );
    }
  } else {
    // Get all current locations for this user.
    const {
      data: allUserLocations,
      error: countError,
    } = await supabase
      .from('recent_locations')
      .select('id')
      .eq('user_id', userId)
      .order('created_at', {
        ascending: false,
      });

    if (countError) {
      throw new Error(
        `Error counting user locations: ${countError.message}`
      );
    }

    // Keep only the newest 9 before inserting
    // the new location.
    if (
      allUserLocations &&
      allUserLocations.length >= 10
    ) {
      const idsToDelete =
        allUserLocations
          .slice(9)
          .map((location) => location.id);

      if (idsToDelete.length > 0) {
        const {
          error: pruneError,
        } = await supabase
          .from('recent_locations')
          .delete()
          .in(
            'id',
            idsToDelete
          );

        if (pruneError) {
          throw new Error(
            `Error pruning old locations: ${pruneError.message}`
          );
        }
      }
    }
  }

  // Insert the new recent location.
  const {
    data: newLocation,
    error: insertError,
  } = await supabase
    .from('recent_locations')
    .insert([
      {
        user_id: userId,
        place_id: placeId,
        name,
        address,
        latitude: Number(latitude),
        longitude: Number(longitude),
        city: city || '',
        state: state || '',
        country: country || '',
      },
    ])
    .select()
    .single();

  if (insertError) {
    throw new Error(
      `Failed to save recent location: ${insertError.message}`
    );
  }

  // Return the same camelCase response shape
  // expected by the Flutter LocationModel.
  return {
    id: newLocation.id,

    placeId: newLocation.place_id,

    name: newLocation.name,

    address: newLocation.address,

    latitude: Number(newLocation.latitude),

    longitude: Number(newLocation.longitude),

    city: newLocation.city || '',

    state: newLocation.state || '',

    country: newLocation.country || '',
  };
};

// -----------------------------------------------------------------------------
// Delete Recent Location
// -----------------------------------------------------------------------------

/**
 * Deletes a recent location by ID
 * for a specific user.
 *
 * @param {string} userId
 * @param {string} locationId
 */
const deleteRecentLocation = async (
  userId,
  locationId
) => {
  if (!userId) {
    throw new Error('User ID is required');
  }

  if (!locationId) {
    throw new Error('Location ID is required');
  }

  const { error } = await supabase
    .from('recent_locations')
    .delete()
    .eq('id', locationId)
    .eq('user_id', userId);

  if (error) {
    throw new Error(
      `Failed to delete recent location: ${error.message}`
    );
  }
};

// -----------------------------------------------------------------------------
// Export location service functions
// -----------------------------------------------------------------------------

module.exports = {
  searchLocations,
  reverseGeocode,
  getPopularLocations,
  getRecentLocations,
  saveRecentLocation,
  deleteRecentLocation,
};