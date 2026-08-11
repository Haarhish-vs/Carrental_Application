const { supabase } = require('../../config/supabase');

const asNumber = (value) => Number(value || 0);

function ratingSummary(rows) {
  const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  for (const row of rows) distribution[row.rating] += 1;
  const total = rows.length;
  const average = total ? rows.reduce((sum, row) => sum + row.rating, 0) / total : 0;
  return { average: Number(average.toFixed(1)), total, distribution };
}

function verificationStatus(rows) {
  const statuses = rows.map((row) => row.verification_status);
  if (statuses.includes('verified')) return 'verified';
  if (statuses.includes('pending')) return 'pending';
  if (statuses.includes('rejected')) return 'rejected';
  if (statuses.includes('expired')) return 'expired';
  return 'not_verified';
}

class ProfileService {
  async getProfile(userId) {
    const [{ data: user, error: userError }, { data: roleRows, error: roleError }] = await Promise.all([
      supabase.from('users').select('*').eq('id', userId).single(),
      supabase.from('user_roles').select('role').eq('user_id', userId),
    ]);
    if (userError || !user) throw new Error(`Unable to load profile: ${userError?.message || 'user not found'}`);
    if (roleError) throw new Error(`Unable to load profile roles: ${roleError.message}`);

    const roles = (roleRows || []).map((row) => row.role);
    if (!roles.includes('customer')) roles.push('customer');

    const [renterBookingsResult, vehiclesResult, customerRatingsResult, ownerRatingsResult, verificationResult] = await Promise.all([
      supabase.from('bookings').select('id, vehicle_id, status, total_price, start_date, end_date, vehicle:vehicles(id, brand, model, odometer_reading)').eq('renter_id', userId),
      supabase.from('vehicles').select('id, brand, model, is_available, odometer_reading').eq('owner_id', userId),
      supabase.from('ratings').select('rating').eq('rated_user_id', userId).eq('rated_role', 'customer'),
      supabase.from('ratings').select('rating').eq('rated_user_id', userId).eq('rated_role', 'owner'),
      supabase.from('user_verification_documents').select('verification_status').eq('user_id', userId).eq('subject_role', 'customer'),
    ]);
    for (const result of [renterBookingsResult, vehiclesResult, customerRatingsResult, ownerRatingsResult, verificationResult]) {
      if (result.error) throw new Error(`Unable to load profile activity: ${result.error.message}`);
    }
    const renterBookings = renterBookingsResult.data || [];
    const vehicles = vehiclesResult.data || [];
    const vehicleIds = vehicles.map((vehicle) => vehicle.id);
    const { data: ownerBookings, error: ownerBookingsError } = vehicleIds.length
      ? await supabase.from('bookings').select('id, vehicle_id, renter_id, status, total_price, end_date').in('vehicle_id', vehicleIds)
      : { data: [], error: null };
    if (ownerBookingsError) throw new Error(`Unable to load hosting activity: ${ownerBookingsError.message}`);

    const now = new Date();
    const today = now.toISOString().slice(0, 10);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().slice(0, 10);
    const completedOwnerBookings = (ownerBookings || []).filter((booking) => booking.status === 'completed' && booking.end_date <= today);
    const earnings = (rows) => rows.reduce((sum, booking) => sum + asNumber(booking.total_price), 0);
    const activeVehicleIds = new Set((ownerBookings || []).filter((booking) => ['confirmed', 'active'].includes(booking.status)).map((booking) => booking.vehicle_id));
    const renterCounts = new Map();
    for (const booking of completedOwnerBookings) renterCounts.set(booking.renter_id, (renterCounts.get(booking.renter_id) || 0) + 1);
    const usage = vehicles.map((vehicle) => ({
      vehicleId: vehicle.id,
      name: `${vehicle.brand} ${vehicle.model}`.trim(),
      rentals: completedOwnerBookings.filter((booking) => booking.vehicle_id === vehicle.id).length,
      distanceKm: vehicle.odometer_reading == null ? null : asNumber(vehicle.odometer_reading),
    })).sort((a, b) => b.rentals - a.rentals);

    return {
      user: {
        id: user.id, full_name: user.full_name, phone_number: user.phone_number, email: user.email,
        profile_photo_url: user.profile_photo_url, location_address: user.location_address,
        location_lat: user.location_lat, location_lng: user.location_lng, business_name: user.business_name,
      },
      roles,
      customer: {
        verificationStatus: verificationStatus(verificationResult.data || []),
        bookings: renterBookings.length,
        currentlyRented: renterBookings.filter((booking) => ['confirmed', 'active'].includes(booking.status)).length,
        completedTrips: renterBookings.filter((booking) => booking.status === 'completed').length,
        rating: ratingSummary(customerRatingsResult.data || []),
      },
      owner: {
        earnings: { total: earnings(completedOwnerBookings), monthly: earnings(completedOwnerBookings.filter((booking) => booking.end_date >= monthStart)), today: earnings(completedOwnerBookings.filter((booking) => booking.end_date === today)) },
        fleet: { total: vehicles.length, available: vehicles.filter((vehicle) => vehicle.is_available && !activeVehicleIds.has(vehicle.id)).length, rented: activeVehicleIds.size },
        repeatRenters: [...renterCounts.values()].filter((count) => count > 1).length,
        rating: ratingSummary(ownerRatingsResult.data || []),
        usage,
      },
    };
  }

  async updateProfile(userId, fields) {
    const allowed = ['full_name', 'email', 'location_address', 'location_lat', 'location_lng', 'business_name'];
    const update = Object.fromEntries(Object.entries(fields).filter(([key, value]) => allowed.includes(key) && value !== undefined));
    if (!Object.keys(update).length) throw new Error('No editable profile fields were supplied');
    const { data, error } = await supabase.from('users').update(update).eq('id', userId).select('*').single();
    if (error) throw new Error(`Unable to update profile: ${error.message}`);
    return data;
  }

  async becomeOwner(userId) {
    const { error } = await supabase.from('user_roles').upsert({ user_id: userId, role: 'owner' }, { onConflict: 'user_id,role' });
    if (error) throw new Error(`Unable to enable hosting: ${error.message}`);
  }

  async setPhoto(userId, photoUrl) {
    const { data, error } = await supabase.from('users').update({ profile_photo_url: photoUrl }).eq('id', userId).select('*').single();
    if (error) throw new Error(`Unable to save profile photo: ${error.message}`);
    return data;
  }

  async submitRating(userId, bookingId, rating) {
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      const error = new Error('Rating must be a whole number from 1 to 5'); error.statusCode = 400; throw error;
    }
    const { data: booking, error: bookingError } = await supabase
      .from('bookings').select('id, renter_id, status, vehicle:vehicles!inner(owner_id)').eq('id', bookingId).single();
    if (bookingError || !booking) { const error = new Error('Booking not found'); error.statusCode = 404; throw error; }
    if (booking.status !== 'completed') { const error = new Error('Ratings can only be submitted after a completed trip'); error.statusCode = 400; throw error; }
    const isRenter = booking.renter_id === userId;
    const isOwner = booking.vehicle.owner_id === userId;
    if (!isRenter && !isOwner) { const error = new Error('You are not allowed to rate this booking'); error.statusCode = 403; throw error; }
    const { error } = await supabase.from('ratings').upsert({
      booking_id: bookingId, rater_id: userId,
      rated_user_id: isRenter ? booking.vehicle.owner_id : booking.renter_id,
      rated_role: isRenter ? 'owner' : 'customer', rating,
    }, { onConflict: 'booking_id,rater_id' });
    if (error) throw new Error(`Unable to save rating: ${error.message}`);
  }
}

module.exports = new ProfileService();
