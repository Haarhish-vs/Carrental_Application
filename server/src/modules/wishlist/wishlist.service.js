// wishlist.service.js
const { supabase } = require('../../config/supabase');

class WishlistService {
  /**
   * Toggles a vehicle in the user's wishlist.
   * If wishlisted -> removes it. If not -> adds it.
   * @param {string} userId - User UUID
   * @param {string} vehicleId - Vehicle UUID
   * @returns {Promise<{ isWishlisted: boolean, vehicleId: string }>}
   */
  async toggleWishlist(userId, vehicleId) {
    if (!userId || !vehicleId) {
      const error = new Error('User ID and Vehicle ID are required');
      error.statusCode = 400;
      throw error;
    }

    // 1. Check if vehicle exists and ensure user is not the owner
    const { data: vehicle, error: vehicleError } = await supabase
      .from('vehicles')
      .select('id, brand, model, owner_id')
      .eq('id', vehicleId)
      .maybeSingle();

    if (vehicleError) {
      throw new Error(`Database error verifying vehicle: ${vehicleError.message}`);
    }

    if (!vehicle) {
      const error = new Error('Vehicle not found');
      error.statusCode = 404;
      throw error;
    }

    if (vehicle.owner_id === userId) {
      const error = new Error('You cannot add your own vehicle to your wishlist');
      error.statusCode = 400;
      throw error;
    }

    // 2. Check if already in wishlist
    const { data: existing, error: checkError } = await supabase
      .from('wishlists')
      .select('id')
      .eq('user_id', userId)
      .eq('vehicle_id', vehicleId)
      .maybeSingle();

    if (checkError) {
      throw new Error(`Database error checking wishlist: ${checkError.message}`);
    }

    if (existing) {
      // Remove from wishlist
      const { error: deleteError } = await supabase
        .from('wishlists')
        .delete()
        .eq('id', existing.id);

      if (deleteError) {
        throw new Error(`Failed to remove vehicle from wishlist: ${deleteError.message}`);
      }

      console.log(`💔 [WishlistService] User ${userId} removed vehicle ${vehicleId} from wishlist`);
      return { isWishlisted: false, vehicleId };
    } else {
      // Insert into wishlist
      const { error: insertError } = await supabase
        .from('wishlists')
        .insert({
          user_id: userId,
          vehicle_id: vehicleId
        });

      if (insertError) {
        throw new Error(`Failed to add vehicle to wishlist: ${insertError.message}`);
      }

      console.log(`❤️ [WishlistService] User ${userId} added vehicle ${vehicleId} to wishlist`);
      return { isWishlisted: true, vehicleId };
    }
  }

  /**
   * Returns array of vehicle IDs wishlisted by the user.
   * Useful for fast initial client-side caching.
   * @param {string} userId - User UUID
   * @returns {Promise<string[]>} Array of vehicle UUIDs
   */
  async getWishlistIds(userId) {
    if (!userId) {
      const error = new Error('User ID is required');
      error.statusCode = 400;
      throw error;
    }

    const { data, error } = await supabase
      .from('wishlists')
      .select('vehicle_id')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch wishlist IDs: ${error.message}`);
    }

    return (data || []).map(row => row.vehicle_id);
  }

  /**
   * Fetches full vehicle details for all cars in the user's wishlist.
   * @param {string} userId - User UUID
   * @returns {Promise<Array<object>>} List of populated vehicle objects
   */
  async getUserWishlist(userId) {
    if (!userId) {
      const error = new Error('User ID is required');
      error.statusCode = 400;
      throw error;
    }

    // Query wishlists joined with vehicles and owner for trust score
    const { data: rows, error } = await supabase
      .from('wishlists')
      .select(`
        id,
        created_at,
        vehicles:vehicle_id (
          *,
          owner:users (
            id,
            full_name,
            trust_score
          )
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error(`❌ [WishlistService.getUserWishlist] Error: ${error.message}`);
      throw new Error(`Failed to fetch user wishlist: ${error.message}`);
    }

    // Extract vehicles and attach wishlisted timestamp and calculated fields
    const vehicles = (rows || [])
      .filter(row => row.vehicles != null)
      .map(row => {
        const v = row.vehicles;
        const rating = v.owner && v.owner.trust_score ? parseFloat((v.owner.trust_score / 20).toFixed(1)) : 4.5;
        const desc = (v.vehicle_description || '').toLowerCase();
        const ac = !desc.includes('no ac') && !desc.includes('no air conditioning');
        const navigation = !desc.includes('no gps') && !desc.includes('no navigation');

        return {
          ...v,
          rating,
          ac,
          navigation,
          wishlist_id: row.id,
          wishlisted_at: row.created_at,
          is_wishlisted: true
        };
      });

    return vehicles;
  }
}

module.exports = new WishlistService();
