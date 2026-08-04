const supabase = require('../../../config/supabase');

class CarRepository {
  /**
   * Find a car by its registration number
   */
  async findByRegistrationNumber(registrationNumber) {
    const { data, error } = await supabase
      .from('cars')
      .select('*')
      .eq('registration_number', registrationNumber)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  /**
   * Create a new car in draft state
   */
  async createCar(carData) {
    const { data, error } = await supabase
      .from('cars')
      .insert([carData])
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Find a car with all its associated details
   */
  async findCarById(id) {
    const { data, error } = await supabase
      .from('cars')
      .select(`
        *,
        car_locations (*),
        car_pricing (*),
        car_availability (*),
        car_documents (*),
        car_images (*)
      `)
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  /**
   * Get all cars with their details
   */
  async findAllCars(filters = {}) {
    let query = supabase
      .from('cars')
      .select(`
        *,
        car_locations (*),
        car_pricing (*),
        car_availability (*),
        car_documents (*),
        car_images (*)
      `);

    if (filters.status) {
      query = query.eq('status', filters.status);
    }
    if (filters.owner_id) {
      query = query.eq('owner_id', filters.owner_id);
    }
    if (filters.brand) {
      query = query.ilike('brand', `%${filters.brand}%`);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data;
  }

  /**
   * Update basic details of a car
   */
  async updateCar(id, carData) {
    const { data, error } = await supabase
      .from('cars')
      .update(carData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Delete a car
   */
  async deleteCar(id) {
    const { data, error } = await supabase
      .from('cars')
      .delete()
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Add a car image
   */
  async addCarImage(imageData) {
    const { data, error } = await supabase
      .from('car_images')
      .insert([imageData])
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Find car images
   */
  async findImagesByCarId(carId) {
    const { data, error } = await supabase
      .from('car_images')
      .select('*')
      .eq('car_id', carId);

    if (error) throw error;
    return data;
  }

  /**
   * Find a car image by its ID
   */
  async findImageById(imageId) {
    const { data, error } = await supabase
      .from('car_images')
      .select('*')
      .eq('id', imageId)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  /**
   * Delete a car image
   */
  async deleteCarImage(imageId) {
    const { data, error } = await supabase
      .from('car_images')
      .delete()
      .eq('id', imageId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Upsert pickup location for a car
   */
  async upsertLocation(carId, locationData) {
    const payload = { car_id: carId, ...locationData };
    const { data, error } = await supabase
      .from('car_locations')
      .upsert(payload, { onConflict: 'car_id' })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Find pickup location
   */
  async findLocationByCarId(carId) {
    const { data, error } = await supabase
      .from('car_locations')
      .select('*')
      .eq('car_id', carId)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  /**
   * Upsert pricing for a car
   */
  async upsertPricing(carId, pricingData) {
    const payload = { car_id: carId, ...pricingData };
    const { data, error } = await supabase
      .from('car_pricing')
      .upsert(payload, { onConflict: 'car_id' })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Find pricing
   */
  async findPricingByCarId(carId) {
    const { data, error } = await supabase
      .from('car_pricing')
      .select('*')
      .eq('car_id', carId)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  /**
   * Upsert availability for a car
   */
  async upsertAvailability(carId, availabilityData) {
    const payload = { car_id: carId, ...availabilityData };
    const { data, error } = await supabase
      .from('car_availability')
      .upsert(payload, { onConflict: 'car_id' })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Find availability
   */
  async findAvailabilityByCarId(carId) {
    const { data, error } = await supabase
      .from('car_availability')
      .select('*')
      .eq('car_id', carId)
      .maybeSingle();

    if (error) throw error;
    return data;
  }

  /**
   * Upsert documents for a car
   */
  async upsertDocuments(carId, documentData) {
    const payload = { car_id: carId, ...documentData };
    const { data, error } = await supabase
      .from('car_documents')
      .upsert(payload, { onConflict: 'car_id' })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Find documents
   */
  async findDocumentsByCarId(carId) {
    const { data, error } = await supabase
      .from('car_documents')
      .select('*')
      .eq('car_id', carId)
      .maybeSingle();

    if (error) throw error;
    return data;
  }
}

module.exports = new CarRepository();
