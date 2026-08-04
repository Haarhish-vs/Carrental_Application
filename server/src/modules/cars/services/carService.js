const fs = require('fs');
const path = require('path');
const carRepository = require('../repositories/carRepository');
const supabase = require('../../../config/supabase');
const { BadRequestError, NotFoundError } = require('../../../utils/errors');

class CarService {
  /**
   * Helper to format car response (snake_case database to camelCase response)
   */
  _mapCarResponse(car) {
    if (!car) return null;
    return {
      id: car.id,
      ownerId: car.owner_id,
      brand: car.brand,
      model: car.model,
      variant: car.variant,
      year: car.year,
      fuelType: car.fuel_type,
      transmission: car.transmission,
      mileage: Number(car.mileage),
      engineCapacity: car.engine_capacity,
      registrationNumber: car.registration_number,
      status: car.status,
      createdAt: car.created_at,
      updatedAt: car.updated_at,
      location: car.car_locations ? this._mapLocationResponse(car.car_locations[0] || car.car_locations) : null,
      pricing: car.car_pricing ? this._mapPricingResponse(car.car_pricing[0] || car.car_pricing) : null,
      availability: car.car_availability ? this._mapAvailabilityResponse(car.car_availability[0] || car.car_availability) : null,
      documents: car.car_documents ? this._mapDocumentsResponse(car.car_documents[0] || car.car_documents) : null,
      images: car.car_images ? car.car_images.map(img => this._mapImageResponse(img)) : []
    };
  }

  _mapLocationResponse(loc) {
    if (!loc) return null;
    return {
      id: loc.id,
      pickupAddress: loc.pickup_address,
      city: loc.city,
      state: loc.state,
      pincode: loc.pincode,
      latitude: Number(loc.latitude),
      longitude: Number(loc.longitude)
    };
  }

  _mapPricingResponse(price) {
    if (!price) return null;
    return {
      id: price.id,
      pricePerDay: Number(price.price_per_day),
      securityDeposit: Number(price.security_deposit),
      minimumRentalDuration: price.minimum_rental_duration,
      instantBooking: price.instant_booking
    };
  }

  _mapAvailabilityResponse(avail) {
    if (!avail) return null;
    return {
      id: avail.id,
      availableDates: avail.available_dates || [],
      blockedDates: avail.blocked_dates || []
    };
  }

  _mapDocumentsResponse(doc) {
    if (!doc) return null;
    return {
      id: doc.id,
      rcUrl: doc.rc_url,
      insuranceUrl: doc.insurance_url,
      fitnessUrl: doc.fitness_url,
      pucUrl: doc.puc_url
    };
  }

  _mapImageResponse(img) {
    if (!img) return null;
    return {
      id: img.id,
      imageUrl: img.image_url,
      imageType: img.image_type
    };
  }

  /**
   * Helper to handle file uploads (Supabase Storage vs Local Storage)
   */
  async _uploadFile(file, bucketName) {
    const useLocalStorage = process.env.USE_LOCAL_STORAGE === 'true';
    if (useLocalStorage) {
      // Return relative path for local serving
      return `/uploads/${file.filename}`;
    }

    // Upload to Supabase Storage
    const fileBuffer = fs.readFileSync(file.path);
    const uniqueFileName = `${Date.now()}-${file.filename}`;
    
    const { data, error } = await supabase.storage
      .from(bucketName)
      .upload(uniqueFileName, fileBuffer, {
        contentType: file.mimetype,
        upsert: true
      });

    if (error) {
      console.error('Supabase storage upload error, falling back to local storage path:', error);
      return `/uploads/${file.filename}`;
    }

    const { data: publicUrlData } = supabase.storage
      .from(bucketName)
      .getPublicUrl(uniqueFileName);

    return publicUrlData.publicUrl;
  }

  /**
   * Create a new car in DRAFT state
   */
  async createCar(carData, ownerId) {
    // Check registration number uniqueness
    const existing = await carRepository.findByRegistrationNumber(carData.registrationNumber);
    if (existing) {
      throw new BadRequestError('Registration number must be unique.');
    }

    const payload = {
      owner_id: ownerId,
      brand: carData.brand,
      model: carData.model,
      variant: carData.variant,
      year: carData.year,
      fuel_type: carData.fuelType,
      transmission: carData.transmission,
      mileage: carData.mileage,
      engine_capacity: carData.engineCapacity,
      registration_number: carData.registrationNumber,
      status: 'DRAFT'
    };

    const newCar = await carRepository.createCar(payload);
    return this._mapCarResponse(newCar);
  }

  /**
   * Get list of all cars
   */
  async getCars(filters = {}) {
    const cars = await carRepository.findAllCars(filters);
    return cars.map(car => this._mapCarResponse(car));
  }

  /**
   * Get car by ID
   */
  async getCarById(id) {
    const car = await carRepository.findCarById(id);
    if (!car) {
      throw new NotFoundError(`Car with ID ${id} not found.`);
    }
    return this._mapCarResponse(car);
  }

  /**
   * Update details of a car
   */
  async updateCar(id, updateData) {
    const car = await carRepository.findCarById(id);
    if (!car) {
      throw new NotFoundError(`Car with ID ${id} not found.`);
    }

    // Business Rule: Users can edit DRAFT cars.
    // If the status is not DRAFT, let's make sure it follows restrictions.
    // Business Rule: Approved cars cannot change their registration number.
    if (car.status === 'APPROVED' && updateData.registrationNumber) {
      if (updateData.registrationNumber !== car.registration_number) {
        throw new BadRequestError('Approved cars cannot change their registration number.');
      }
    }

    // If changing registration number, check uniqueness
    if (updateData.registrationNumber && updateData.registrationNumber !== car.registration_number) {
      const existing = await carRepository.findByRegistrationNumber(updateData.registrationNumber);
      if (existing) {
        throw new BadRequestError('Registration number must be unique.');
      }
    }

    const payload = {};
    if (updateData.brand !== undefined) payload.brand = updateData.brand;
    if (updateData.model !== undefined) payload.model = updateData.model;
    if (updateData.variant !== undefined) payload.variant = updateData.variant;
    if (updateData.year !== undefined) payload.year = updateData.year;
    if (updateData.fuelType !== undefined) payload.fuel_type = updateData.fuelType;
    if (updateData.transmission !== undefined) payload.transmission = updateData.transmission;
    if (updateData.mileage !== undefined) payload.mileage = updateData.mileage;
    if (updateData.engineCapacity !== undefined) payload.engine_capacity = updateData.engineCapacity;
    if (updateData.registrationNumber !== undefined) payload.registration_number = updateData.registrationNumber;

    const updatedCar = await carRepository.updateCar(id, payload);
    return this._mapCarResponse(updatedCar);
  }

  /**
   * Delete a draft car
   */
  async deleteCar(id) {
    const car = await carRepository.findCarById(id);
    if (!car) {
      throw new NotFoundError(`Car with ID ${id} not found.`);
    }

    // Business Rule: Only DRAFT cars can be deleted.
    if (car.status !== 'DRAFT') {
      throw new BadRequestError('Only cars with DRAFT status can be deleted.');
    }

    await carRepository.deleteCar(id);
    return { id, message: 'Draft car deleted successfully' };
  }

  /**
   * Add image for a car
   */
  async addImages(carId, files) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }

    // Check if the car is editable (DRAFT status)
    if (car.status !== 'DRAFT') {
      throw new BadRequestError('Images can only be uploaded to DRAFT cars.');
    }

    const existingImages = await carRepository.findImagesByCarId(carId);
    
    // Business Rule: Maximum 10 images
    const totalCount = existingImages.length + files.length;
    if (totalCount > 10) {
      throw new BadRequestError(`Cannot upload images. Maximum limit is 10 images. Currently has ${existingImages.length}.`);
    }

    const addedImages = [];
    for (const file of files) {
      const imageUrl = await this._uploadFile(file, 'car-images');
      // Infer image type from filename prefix or default to 'Other'
      // Fieldnames might be 'front', 'back', 'left', 'right', 'interior', 'dashboard'
      const imageType = file.fieldname ? file.fieldname.toUpperCase() : 'OTHER';

      const img = await carRepository.addCarImage({
        car_id: carId,
        image_url: imageUrl,
        image_type: imageType
      });
      addedImages.push(this._mapImageResponse(img));
    }

    return addedImages;
  }

  /**
   * Get all images of a car
   */
  async getImages(carId) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }
    const images = await carRepository.findImagesByCarId(carId);
    return images.map(img => this._mapImageResponse(img));
  }

  /**
   * Delete an image
   */
  async deleteImage(carId, imageId) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }

    // Only DRAFT cars can edit images
    if (car.status !== 'DRAFT') {
      throw new BadRequestError('Images can only be deleted from DRAFT cars.');
    }

    const image = await carRepository.findImageById(imageId);
    if (!image || image.car_id !== carId) {
      throw new NotFoundError(`Image with ID ${imageId} not found for this car.`);
    }

    // Delete image from database
    await carRepository.deleteCarImage(imageId);

    // Optionally try to delete file from local storage if relevant
    if (image.image_url.startsWith('/uploads/')) {
      const filePath = path.join(process.cwd(), image.image_url);
      if (fs.existsSync(filePath)) {
        try {
          fs.unlinkSync(filePath);
        } catch (e) {
          console.error('Failed to delete local file:', e);
        }
      }
    }

    return { id: imageId, message: 'Image deleted successfully' };
  }

  /**
   * Save pickup location
   */
  async saveLocation(carId, locationData) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }

    if (car.status !== 'DRAFT') {
      throw new BadRequestError('Location can only be set or modified for DRAFT cars.');
    }

    const payload = {
      pickup_address: locationData.pickupAddress,
      city: locationData.city,
      state: locationData.state,
      pincode: locationData.pincode,
      latitude: locationData.latitude,
      longitude: locationData.longitude
    };

    const location = await carRepository.upsertLocation(carId, payload);
    return this._mapLocationResponse(location);
  }

  /**
   * Get pickup location
   */
  async getLocation(carId) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }
    const location = await carRepository.findLocationByCarId(carId);
    if (!location) {
      throw new NotFoundError(`Pickup location not configured for car ${carId}.`);
    }
    return this._mapLocationResponse(location);
  }

  /**
   * Save pricing details
   */
  async savePricing(carId, pricingData) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }

    if (car.status !== 'DRAFT') {
      throw new BadRequestError('Pricing can only be configured for DRAFT cars.');
    }

    const payload = {
      price_per_day: pricingData.pricePerDay,
      security_deposit: pricingData.securityDeposit,
      minimum_rental_duration: pricingData.minimumRentalDuration,
      instant_booking: pricingData.instantBooking || false
    };

    const pricing = await carRepository.upsertPricing(carId, payload);
    return this._mapPricingResponse(pricing);
  }

  /**
   * Get pricing details
   */
  async getPricing(carId) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }
    const pricing = await carRepository.findPricingByCarId(carId);
    if (!pricing) {
      throw new NotFoundError(`Pricing details not configured for car ${carId}.`);
    }
    return this._mapPricingResponse(pricing);
  }

  /**
   * Save availability details
   */
  async saveAvailability(carId, availabilityData) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }

    if (car.status !== 'DRAFT') {
      throw new BadRequestError('Availability can only be configured for DRAFT cars.');
    }

    const payload = {
      available_dates: availabilityData.availableDates || [],
      blocked_dates: availabilityData.blockedDates || []
    };

    const availability = await carRepository.upsertAvailability(carId, payload);
    return this._mapAvailabilityResponse(availability);
  }

  /**
   * Get availability details
   */
  async getAvailability(carId) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }
    const availability = await carRepository.findAvailabilityByCarId(carId);
    if (!availability) {
      throw new NotFoundError(`Availability details not configured for car ${carId}.`);
    }
    return this._mapAvailabilityResponse(availability);
  }

  /**
   * Upload and save documents
   */
  async saveDocuments(carId, files) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }

    if (car.status !== 'DRAFT') {
      throw new BadRequestError('Documents can only be uploaded to DRAFT cars.');
    }

    const payload = {};
    
    // files is an object with keys representing the fields: rc, insurance, fitness, puc
    if (files.rc && files.rc[0]) {
      payload.rc_url = await this._uploadFile(files.rc[0], 'car-documents');
    }
    if (files.insurance && files.insurance[0]) {
      payload.insurance_url = await this._uploadFile(files.insurance[0], 'car-documents');
    }
    if (files.fitness && files.fitness[0]) {
      payload.fitness_url = await this._uploadFile(files.fitness[0], 'car-documents');
    }
    if (files.puc && files.puc[0]) {
      payload.puc_url = await this._uploadFile(files.puc[0], 'car-documents');
    }

    // Merge with existing document urls if any
    const existingDoc = await carRepository.findDocumentsByCarId(carId);
    const mergedPayload = { ...existingDoc, ...payload };

    const documents = await carRepository.upsertDocuments(carId, mergedPayload);
    return this._mapDocumentsResponse(documents);
  }

  /**
   * Get documents URLs
   */
  async getDocuments(carId) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }
    const documents = await carRepository.findDocumentsByCarId(carId);
    if (!documents) {
      throw new NotFoundError(`Documents details not configured for car ${carId}.`);
    }
    return this._mapDocumentsResponse(documents);
  }

  /**
   * Submit car for verification
   */
  async submitCar(carId) {
    const car = await carRepository.findCarById(carId);
    if (!car) {
      throw new NotFoundError(`Car with ID ${carId} not found.`);
    }

    if (car.status !== 'DRAFT') {
      throw new BadRequestError(`Cannot submit car. Status must be DRAFT, current status is ${car.status}.`);
    }

    // Optional completeness verification before submission
    // Let's check if they filled out the required steps: location, pricing, documents, images
    const location = await carRepository.findLocationByCarId(carId);
    const pricing = await carRepository.findPricingByCarId(carId);
    const documents = await carRepository.findDocumentsByCarId(carId);
    const images = await carRepository.findImagesByCarId(carId);

    const missingSteps = [];
    if (!location) missingSteps.push('Location details');
    if (!pricing) missingSteps.push('Pricing details');
    if (!documents || !documents.rc_url) missingSteps.push('Registration Certificate (RC) document');
    if (images.length === 0) missingSteps.push('Car images (at least 1 is required)');

    if (missingSteps.length > 0) {
      throw new BadRequestError(`Cannot submit car. Please complete: ${missingSteps.join(', ')}.`);
    }

    // Update status to PENDING_VERIFICATION
    const updatedCar = await carRepository.updateCar(carId, { status: 'PENDING_VERIFICATION' });
    return this._mapCarResponse(updatedCar);
  }
}

module.exports = new CarService();
