// search_cars.test.js
const request = require('supertest');
const app = require('../src/app');
const { supabase } = require('../src/config/supabase');

// Mock Supabase Client
jest.mock('../src/config/supabase', () => {
  const mockSingle = jest.fn();
  const mockMaybeSingle = jest.fn();

  const mockQueryBuilder = {
    select: jest.fn().mockReturnThis(),
    insert: jest.fn().mockReturnThis(),
    update: jest.fn().mockReturnThis(),
    delete: jest.fn().mockReturnThis(),
    eq: jest.fn().mockReturnThis(),
    in: jest.fn().mockReturnThis(),
    lte: jest.fn().mockReturnThis(),
    gte: jest.fn().mockReturnThis(),
    lt: jest.fn().mockReturnThis(),
    order: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    range: jest.fn().mockReturnThis(),
    ilike: jest.fn().mockReturnThis(),
    not: jest.fn().mockReturnThis(),
    single: mockSingle,
    maybeSingle: mockMaybeSingle,

    _data: null,
    _error: null,
    then(onFulfilled) {
      return Promise.resolve({ data: this._data, error: this._error }).then(onFulfilled);
    }
  };

  return {
    supabase: {
      from: jest.fn(() => mockQueryBuilder)
    },
    supabaseAnon: {}
  };
});

describe('Search Cars & Dynamic Filter Options Backend Tests', () => {
  let builder;

  beforeEach(() => {
    jest.clearAllMocks();
    builder = supabase.from();
    builder._data = null;
    builder._error = null;
  });

  describe('GET /api/cars/filter-options & /api/vehicles/filter-options', () => {
    it('1 & 2. should retrieve dynamic database-driven filter options without hardcoding', async () => {
      const mockVehicles = [
        { fuel_type: 'Diesel', transmission: 'Automatic', seats: 7, price_per_day: 5000, car_type: 'SUV', status: 'active' },
        { fuel_type: 'Electric', transmission: 'Automatic', seats: 5, price_per_day: 3000, car_type: 'Sedan', status: 'active' },
        { fuel_type: 'Hybrid', transmission: 'Manual', seats: 5, price_per_day: 4500, car_type: 'Hatchback', status: 'active' }
      ];
      builder._data = mockVehicles;

      const res = await request(app).get('/api/cars/filter-options');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.filters).toBeDefined();
      expect(res.body.filters.fuelTypes).toContain('Diesel');
      expect(res.body.filters.fuelTypes).toContain('Electric');
      expect(res.body.filters.fuelTypes).toContain('Hybrid');
      expect(res.body.filters.transmissions).toContain('Automatic');
      expect(res.body.filters.transmissions).toContain('Manual');
      expect(res.body.filters.seatOptions).toEqual([5, 7]);
      expect(res.body.filters.priceRange).toEqual({ min: 3000, max: 5000 });

      // Test alias endpoint
      const aliasRes = await request(app).get('/api/vehicles/filter-options');
      expect(aliasRes.status).toBe(200);
      expect(aliasRes.body.success).toBe(true);
    });
  });

  describe('POST /api/cars/search - Validation', () => {
    it('17. should return 400 if return date/time is before pickup date/time', async () => {
      const res = await request(app)
        .post('/api/cars/search')
        .send({
          location: 'Coimbatore',
          pickupDate: '2026-09-20',
          pickupTime: '12:00',
          returnDate: '2026-09-18',
          returnTime: '10:00'
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('strictly after pickup date');
    });

    it('18. should return 400 if location is missing', async () => {
      const res = await request(app)
        .post('/api/cars/search')
        .send({
          pickupDate: '2026-09-20',
          pickupTime: '10:00',
          returnDate: '2026-09-22',
          returnTime: '10:00'
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Location is required');
    });

    it('19. should return 400 if an invalid sort option is provided', async () => {
      const res = await request(app)
        .post('/api/cars/search')
        .send({
          location: 'Coimbatore',
          pickupDate: '2026-09-20',
          pickupTime: '10:00',
          returnDate: '2026-09-22',
          returnTime: '10:00',
          sort: 'invalid_sort_key'
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Invalid sort option');
    });
  });

  describe('POST /api/cars/search - Search Execution & Filters', () => {
    const mockVehicleList = [
      {
        id: 'car-1',
        brand: 'Toyota',
        model: 'Innova Crysta',
        city: 'Coimbatore',
        pickup_location: 'Airport Coimbatore',
        location_lat: 11.02,
        location_lng: 77.03,
        fuel_type: 'Diesel',
        transmission: 'Automatic',
        seats: 7,
        price_per_day: 5000,
        deposit_amount: 5000,
        delivery_fee: 500,
        status: 'active',
        is_available: true,
        images: ['https://example.com/car1.jpg'],
        created_at: '2026-08-01T10:00:00Z',
        owner: { trust_score: 95 }
      },
      {
        id: 'car-2',
        brand: 'Tata',
        model: 'Nexon EV',
        city: 'Coimbatore',
        pickup_location: 'Gandhipuram Coimbatore',
        location_lat: 11.01,
        location_lng: 76.96,
        fuel_type: 'Electric',
        transmission: 'Automatic',
        seats: 5,
        price_per_day: 3000,
        deposit_amount: 2000,
        delivery_fee: 300,
        status: 'active',
        is_available: true,
        images: ['https://example.com/car2.jpg'],
        created_at: '2026-08-05T10:00:00Z',
        owner: { trust_score: 85 }
      },
      {
        id: 'car-3',
        brand: 'Hyundai',
        model: 'i20',
        city: 'Chennai',
        pickup_location: 'Central Chennai',
        location_lat: 13.08,
        location_lng: 80.27,
        fuel_type: 'Petrol',
        transmission: 'Manual',
        seats: 5,
        price_per_day: 2000,
        deposit_amount: 1500,
        delivery_fee: 200,
        status: 'active',
        is_available: true,
        images: ['https://example.com/car3.jpg'],
        created_at: '2026-08-08T10:00:00Z',
        owner: { trust_score: 90 }
      }
    ];

    it('3. should search cars in Coimbatore and return matching available cars', async () => {
      // Mock vehicles return
      builder._data = mockVehicleList;

      const res = await request(app)
        .post('/api/cars/search')
        .send({
          location: {
            name: 'Coimbatore',
            city: 'Coimbatore',
            latitude: 11.0168,
            longitude: 76.9558
          },
          pickupDate: '2026-09-10',
          pickupTime: '10:00',
          returnDate: '2026-09-15',
          returnTime: '10:00'
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.cars.length).toBe(2);
      expect(res.body.cars.map(c => c.id)).toContain('car-1');
      expect(res.body.cars.map(c => c.id)).toContain('car-2');
      expect(res.body.cars.map(c => c.id)).not.toContain('car-3'); // Chennai excluded
    });

    it('4. should return count 0 and empty list with friendly message when no cars match', async () => {
      builder._data = mockVehicleList;

      const res = await request(app)
        .post('/api/cars/search')
        .send({
          location: 'Kolkata',
          pickupDate: '2026-09-10',
          pickupTime: '10:00',
          returnDate: '2026-09-15',
          returnTime: '10:00'
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.count).toBe(0);
      expect(res.body.cars).toEqual([]);
      expect(res.body.message).toContain('No cars are available');
    });

    it('6. should filter by fuelType (Electric)', async () => {
      builder._data = mockVehicleList;

      const res = await request(app)
        .post('/api/cars/search')
        .send({
          location: 'Coimbatore',
          pickupDate: '2026-09-10',
          pickupTime: '10:00',
          returnDate: '2026-09-15',
          returnTime: '10:00',
          filters: {
            fuelType: 'Electric'
          }
        });

      expect(res.status).toBe(200);
      expect(res.body.cars.length).toBe(1);
      expect(res.body.cars[0].id).toBe('car-2');
      expect(res.body.cars[0].fuelType).toBe('Electric');
    });

    it('7. should filter by transmission (Automatic)', async () => {
      builder._data = mockVehicleList;

      const res = await request(app)
        .post('/api/cars/search')
        .send({
          location: 'Coimbatore',
          pickupDate: '2026-09-10',
          pickupTime: '10:00',
          returnDate: '2026-09-15',
          returnTime: '10:00',
          filters: {
            transmission: 'Automatic'
          }
        });

      expect(res.status).toBe(200);
      expect(res.body.cars.length).toBe(2);
    });

    it('8. should filter by seats (7 seats minimum)', async () => {
      builder._data = mockVehicleList;

      const res = await request(app)
        .post('/api/cars/search')
        .send({
          location: 'Coimbatore',
          pickupDate: '2026-09-10',
          pickupTime: '10:00',
          returnDate: '2026-09-15',
          returnTime: '10:00',
          filters: {
            seats: 7
          }
        });

      expect(res.status).toBe(200);
      expect(res.body.cars.length).toBe(1);
      expect(res.body.cars[0].id).toBe('car-1');
      expect(res.body.cars[0].seats).toBe(7);
    });

    it('9. should filter by price range (minPrice: 4000, maxPrice: 6000)', async () => {
      builder._data = mockVehicleList;

      const res = await request(app)
        .post('/api/cars/search')
        .send({
          location: 'Coimbatore',
          pickupDate: '2026-09-10',
          pickupTime: '10:00',
          returnDate: '2026-09-15',
          returnTime: '10:00',
          filters: {
            minPrice: 4000,
            maxPrice: 6000
          }
        });

      expect(res.status).toBe(200);
      expect(res.body.cars.length).toBe(1);
      expect(res.body.cars[0].id).toBe('car-1');
    });

    it('11. should sort price_low_to_high', async () => {
      builder._data = mockVehicleList;

      const res = await request(app)
        .post('/api/cars/search')
        .send({
          location: 'Coimbatore',
          pickupDate: '2026-09-10',
          pickupTime: '10:00',
          returnDate: '2026-09-15',
          returnTime: '10:00',
          sort: 'price_low_to_high'
        });

      expect(res.status).toBe(200);
      expect(res.body.cars.length).toBe(2);
      expect(res.body.cars[0].pricePerDay).toBe(3000);
      expect(res.body.cars[1].pricePerDay).toBe(5000);
    });

    it('12. should sort price_high_to_low', async () => {
      builder._data = mockVehicleList;

      const res = await request(app)
        .post('/api/cars/search')
        .send({
          location: 'Coimbatore',
          pickupDate: '2026-09-10',
          pickupTime: '10:00',
          returnDate: '2026-09-15',
          returnTime: '10:00',
          sort: 'price_high_to_low'
        });

      expect(res.status).toBe(200);
      expect(res.body.cars.length).toBe(2);
      expect(res.body.cars[0].pricePerDay).toBe(5000);
      expect(res.body.cars[1].pricePerDay).toBe(3000);
    });

    it('15. should sort newest first', async () => {
      builder._data = mockVehicleList;

      const res = await request(app)
        .post('/api/cars/search')
        .send({
          location: 'Coimbatore',
          pickupDate: '2026-09-10',
          pickupTime: '10:00',
          returnDate: '2026-09-15',
          returnTime: '10:00',
          sort: 'newest'
        });

      expect(res.status).toBe(200);
      expect(res.body.cars.length).toBe(2);
      expect(res.body.cars[0].id).toBe('car-2'); // created Aug 5
      expect(res.body.cars[1].id).toBe('car-1'); // created Aug 1
    });

    it('20. should support GET /api/cars/search query parameters and route aliases', async () => {
      builder._data = mockVehicleList;

      const res = await request(app)
        .get('/api/cars/search?location=Coimbatore&pickupDate=2026-09-10&pickupTime=10:00&returnDate=2026-09-15&returnTime=10:00');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.cars.length).toBe(2);

      const aliasRes = await request(app)
        .post('/api/vehicles/search')
        .send({
          location: 'Coimbatore',
          pickupDate: '2026-09-10',
          pickupTime: '10:00',
          returnDate: '2026-09-15',
          returnTime: '10:00'
        });

      expect(aliasRes.status).toBe(200);
      expect(aliasRes.body.success).toBe(true);
      expect(aliasRes.body.cars.length).toBe(2);
    });
  });
});
