// wishlist.test.js
const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../src/app');
const { supabase } = require('../src/config/supabase');
const env = require('../src/config/env');

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
    order: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
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

describe('Wishlist Module Tests', () => {
  let testToken;
  const testUserId = 'user-uuid-111';
  const testVehicleId = 'vehicle-uuid-222';
  let builder;

  beforeAll(() => {
    const payload = {
      aud: 'authenticated',
      sub: testUserId,
      role: 'authenticated'
    };
    testToken = jwt.sign(payload, env.JWT_SECRET);
  });

  beforeEach(() => {
    jest.clearAllMocks();
    builder = supabase.from();
    builder._data = null;
    builder._error = null;
  });

  describe('Authentication Guard', () => {
    it('should return 401 Unauthorized for GET /api/wishlist without token', async () => {
      const res = await request(app).get('/api/wishlist');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should return 401 Unauthorized for POST /api/wishlist/toggle without token', async () => {
      const res = await request(app)
        .post('/api/wishlist/toggle')
        .send({ vehicleId: testVehicleId });
      expect(res.status).toBe(401);
    });
  });

  describe('POST /api/wishlist/toggle', () => {
    it('should return 400 if vehicleId is missing', async () => {
      builder.single.mockResolvedValueOnce({
        data: { id: testUserId, full_name: 'Test User' },
        error: null
      });

      const res = await request(app)
        .post('/api/wishlist/toggle')
        .set('Authorization', `Bearer ${testToken}`)
        .send({});

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should add vehicle to wishlist if not already wishlisted', async () => {
      // 1. Auth middleware check
      builder.single.mockResolvedValueOnce({
        data: { id: testUserId, full_name: 'Test User' },
        error: null
      });

      // 2. Vehicle exists check
      builder.maybeSingle
        .mockResolvedValueOnce({
          data: { id: testVehicleId, brand: 'Toyota', model: 'Innova' },
          error: null
        })
        // 3. Check if in wishlist (returns null -> not wishlisted)
        .mockResolvedValueOnce({
          data: null,
          error: null
        });

      // 4. Insert into wishlist
      builder._error = null;

      const res = await request(app)
        .post('/api/wishlist/toggle')
        .set('Authorization', `Bearer ${testToken}`)
        .send({ vehicleId: testVehicleId });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isWishlisted).toBe(true);
      expect(res.body.data.vehicleId).toBe(testVehicleId);
    });

    it('should remove vehicle from wishlist if already wishlisted', async () => {
      // 1. Auth check
      builder.single.mockResolvedValueOnce({
        data: { id: testUserId, full_name: 'Test User' },
        error: null
      });

      // 2. Vehicle check
      builder.maybeSingle
        .mockResolvedValueOnce({
          data: { id: testVehicleId, brand: 'Toyota', model: 'Innova' },
          error: null
        })
        // 3. Wishlist check (returns existing row)
        .mockResolvedValueOnce({
          data: { id: 'wishlist-entry-999' },
          error: null
        });

      const res = await request(app)
        .post('/api/wishlist/toggle')
        .set('Authorization', `Bearer ${testToken}`)
        .send({ vehicleId: testVehicleId });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isWishlisted).toBe(false);
      expect(res.body.data.vehicleId).toBe(testVehicleId);
    });
  });

  describe('GET /api/wishlist/ids', () => {
    it('should return list of wishlisted vehicle IDs', async () => {
      // 1. Auth check
      builder.single.mockResolvedValueOnce({
        data: { id: testUserId, full_name: 'Test User' },
        error: null
      });

      // 2. Wishlist IDs query
      builder._data = [
        { vehicle_id: 'veh-1' },
        { vehicle_id: 'veh-2' }
      ];

      const res = await request(app)
        .get('/api/wishlist/ids')
        .set('Authorization', `Bearer ${testToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toEqual(['veh-1', 'veh-2']);
    });
  });

  describe('GET /api/wishlist', () => {
    it('should return populated vehicle list for user', async () => {
      // 1. Auth check
      builder.single.mockResolvedValueOnce({
        data: { id: testUserId, full_name: 'Test User' },
        error: null
      });

      // 2. Full wishlist query with joined vehicle
      builder._data = [
        {
          id: 'wish-1',
          created_at: '2026-08-11T12:00:00Z',
          vehicles: {
            id: 'veh-1',
            brand: 'Hyundai',
            model: 'Creta',
            price_per_day: 3500,
            city: 'Coimbatore',
            images: ['https://example.com/car.jpg'],
            status: 'active',
            is_available: true
          }
        }
      ];

      const res = await request(app)
        .get('/api/wishlist')
        .set('Authorization', `Bearer ${testToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.count).toBe(1);
      expect(res.body.data[0].id).toBe('veh-1');
      expect(res.body.data[0].brand).toBe('Hyundai');
      expect(res.body.data[0].is_wishlisted).toBe(true);
    });
  });
});
