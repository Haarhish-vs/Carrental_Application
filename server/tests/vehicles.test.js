// vehicles.test.js
const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../src/app');
const { supabase } = require('../src/config/supabase');
const env = require('../src/config/env');

// Mock Cloudinary SDK
jest.mock('cloudinary', () => ({
  v2: {
    config: jest.fn(),
    uploader: {
      upload_stream: jest.fn((options, callback) => {
        const stream = {
          end: jest.fn((buffer) => {
            callback(null, { secure_url: 'https://res.cloudinary.com/doymxkmea/image/upload/v12345/vehicles/mock_test_car.jpg' });
          })
        };
        return stream;
      })
    }
  }
}));

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
    single: mockSingle,
    maybeSingle: mockMaybeSingle,
    not: jest.fn().mockReturnThis(),
    
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

describe('Vehicles Module Tests (Listing & Browsing)', () => {
  let testToken;
  const ownerId = 'owner-uuid-123';
  let builder;

  beforeAll(() => {
    const payload = {
      aud: 'authenticated',
      sub: ownerId,
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

  describe('GET /api/vehicles (Public)', () => {
    it('should browse active & available vehicles without authentication', async () => {
      builder._data = [{ id: 'car-1', brand: 'Tesla', model: 'Model 3', status: 'active', is_available: true }];
      builder._error = null;

      const res = await request(app).get('/api/vehicles');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data[0].brand).toBe('Tesla');
    });
    it('should return 401 if uploading media without auth token', async () => {
      const res = await request(app)
        .post('/api/vehicles/upload');

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should upload files successfully when authorized', async () => {
      builder.single.mockResolvedValueOnce({
        data: { id: ownerId, phone_number: '+12345', full_name: 'Owner Name' },
        error: null
      });

      const res = await request(app)
        .post('/api/vehicles/upload')
        .set('Authorization', `Bearer ${testToken}`)
        .attach('files', Buffer.from('dummy image content'), 'test_car.jpg');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data[0]).toContain('cloudinary.com');
    });
  });

  describe('POST /api/vehicles (Protected)', () => {
    it('should reject creation if no authorization token is provided', async () => {
      const res = await request(app)
        .post('/api/vehicles')
        .send({ brand: 'Audi', model: 'A4', fuelType: 'Diesel', transmission: 'Automatic', seatingCapacity: 5, rc_number: 'RC123', city: 'Dallas' });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should allow creation if token is valid and create listing under review', async () => {
      builder.single
        .mockResolvedValueOnce({
          data: { id: ownerId, phone_number: '+12345', full_name: 'Owner Name' },
          error: null
        }) // profile load
        .mockResolvedValueOnce({
          data: { id: 'new-car-id', brand: 'BMW', model: 'X5', owner_id: ownerId, status: 'under_review', is_available: true },
          error: null
        }); // car creation insert

      const res = await request(app)
        .post('/api/vehicles')
        .set('Authorization', `Bearer ${testToken}`)
        .send({
          brand: 'BMW',
          model: 'X5',
          fuelType: 'Petrol',
          transmission: 'Automatic',
          seatingCapacity: 5,
          rc_number: 'RC BMW',
          dailyPrice: 150,
          city: 'Miami'
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('under_review');
    });

    it('should accept large JSON body with Base64 images without PayloadTooLargeError', async () => {
      builder.single
        .mockResolvedValueOnce({
          data: { id: ownerId, phone_number: '+12345', full_name: 'Owner Name' },
          error: null
        })
        .mockResolvedValueOnce({
          data: { id: 'large-car-id', brand: 'Audi', model: 'Q7', owner_id: ownerId, status: 'under_review', is_available: true },
          error: null
        });

      // Generate a ~2MB dummy Base64 payload string
      const largeBase64 = 'data:image/jpeg;base64,' + 'A'.repeat(2 * 1024 * 1024);

      const res = await request(app)
        .post('/api/vehicles')
        .set('Authorization', `Bearer ${testToken}`)
        .send({
          brand: 'Audi',
          model: 'Q7',
          fuelType: 'Diesel',
          transmission: 'Automatic',
          seatingCapacity: 7,
          rc_number: 'RC LARGE',
          dailyPrice: 250,
          city: 'Chicago',
          images: [largeBase64]
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
    });
  });

  describe('PATCH /api/vehicles/:id (Activation & RC Restriction)', () => {
    it('should prevent vehicle activation if RC book is not verified', async () => {
      builder.single.mockResolvedValueOnce({ data: { id: ownerId }, error: null }); // profile verify

      builder.maybeSingle
        .mockResolvedValueOnce({ data: { id: 'car-id', owner_id: ownerId, status: 'under_review' }, error: null }) // vehicle query
        .mockResolvedValueOnce({ data: null, error: null }); // doc query

      const res = await request(app)
        .patch('/api/vehicles/car-id')
        .set('Authorization', `Bearer ${testToken}`)
        .send({ status: 'active' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('RC book document is verified');
    });
  });

  describe('PATCH /api/vehicles/:id/availability (Owner Only)', () => {
    it('should reject availability toggle if user is not the owner', async () => {
      builder.single.mockResolvedValueOnce({ data: { id: ownerId }, error: null }); // profile check
      builder.maybeSingle.mockResolvedValueOnce({ data: { owner_id: 'different-owner-id' }, error: null }); // vehicle check

      const res = await request(app)
        .patch('/api/vehicles/car-id/availability')
        .set('Authorization', `Bearer ${testToken}`)
        .send({ isAvailable: false });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });
  });
});
