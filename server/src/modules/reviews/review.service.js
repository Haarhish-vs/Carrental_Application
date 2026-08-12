const { supabase } = require('../../config/supabase');
const bookingService = require('../bookings/booking.service');

class ReviewService {
  /**
   * Submit a review for a completed or active booking.
   * Also automatically completes the trip.
   */
  async submitReview(userId, data) {
    const { vehicle_id, booking_id, rating, feedback } = data;

    if (!vehicle_id || !booking_id || !rating) {
      const error = new Error('vehicle_id, booking_id, and rating are required');
      error.statusCode = 400;
      throw error;
    }

    // Verify booking belongs to this user and is for this vehicle
    const booking = await bookingService.getBookingById(booking_id, userId);
    
    if (booking.renter_id !== userId) {
      const error = new Error('Only the renter can submit a review');
      error.statusCode = 403;
      throw error;
    }

    if (booking.vehicle_id !== vehicle_id) {
      const error = new Error('Booking does not match the vehicle');
      error.statusCode = 400;
      throw error;
    }

    // Check if review already exists for this booking
    const { data: existingReview } = await supabase
      .from('reviews')
      .select('id')
      .eq('booking_id', booking_id)
      .maybeSingle();

    if (existingReview) {
      const error = new Error('You have already submitted a review for this booking');
      error.statusCode = 400;
      throw error;
    }

    // Automatically transition booking to 'completed' if it isn't already
    if (booking.status === 'active') {
      const { error: updateError } = await supabase
        .from('bookings')
        .update({
          status: 'completed',
          updated_at: new Date().toISOString()
        })
        .eq('id', booking_id);
      
      if (updateError) {
         console.error('Error auto-completing booking:', updateError);
      } else {
         // Free up vehicle availability since it's completed
         // using the service's private method workaround by calling owner's complete? 
         // Actually, let's just restore it directly here since we bypass the strict owner check
         const { error: vehicleUpdateError } = await supabase
          .from('vehicles')
          .update({ is_available: true })
          .eq('id', vehicle_id);
         if (vehicleUpdateError) console.error('Error restoring vehicle:', vehicleUpdateError);
      }
    }

    // Insert the review
    const { data: newReview, error: insertError } = await supabase
      .from('reviews')
      .insert([{
        vehicle_id,
        booking_id,
        renter_id: userId,
        rating,
        feedback
      }])
      .select()
      .single();

    if (insertError) {
      throw new Error(`Failed to submit review: ${insertError.message}`);
    }

    return newReview;
  }

  /**
   * Get all reviews for a vehicle
   */
  async getVehicleReviews(vehicleId) {
    const { data, error } = await supabase
      .from('reviews')
      .select(`
        id,
        rating,
        feedback,
        created_at,
        renter:renter_id (
          full_name,
          profile_image_url
        )
      `)
      .eq('vehicle_id', vehicleId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch reviews: ${error.message}`);
    }

    return data;
  }
}

module.exports = new ReviewService();
