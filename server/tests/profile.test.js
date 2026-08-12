// profile.test.js
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
            callback(null, {
              secure_url: 'https://res.cloudinary.com/doymxkmea/image/upload/v12345/car_rental/profiles/mock_avatar.jpg'
            });
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

describe('Profile Module Tests', () => {
  let testToken;
  const testUserId = 'user-uuid-999';
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

  describe('GET /api/profile', () => {
    it('should return 401 Unauthorized if no JWT token is provided', async () => {
      const res = await request(app).get('/api/profile');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should return user profile with dynamic activity metrics and account types', async () => {
      // 1. Mock profile auth middleware check
      builder.single
        .mockResolvedValueOnce({
          data: { id: testUserId, phone_number: '+919876543210', full_name: 'Haarhish' },
          error: null
        })
        // 2. Mock profile service getProfile query
        .mockResolvedValueOnce({
          data: {
            id: testUserId,
            full_name: 'Haarhish',
            phone_number: '+919876543210',
            profile_image_url: 'https://cloudinary.com/avatar.jpg',
            is_dl_verified: true,
            trust_score: 96,
            created_at: new Date().toISOString()
          },
          error: null
        });

      builder.maybeSingle
        .mockResolvedValueOnce({
          data: {
            id: testUserId,
            full_name: 'Haarhish',
            phone_number: '+919876543210',
            profile_image_url: 'https://cloudinary.com/avatar.jpg',
            is_dl_verified: true,
            trust_score: 96,
            created_at: new Date().toISOString()
          },
          error: null
        });

      const res = await request(app)
        .get('/api/profile')
        .set('Authorization', `Bearer ${testToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.fullName).toBe('Haarhish');
      expect(res.body.data.accountType).toBeDefined();
      expect(res.body.data.activity).toBeDefined();
      expect(res.body.data.rating).toBe(4.8);
    });
  });

  describe('PUT /api/profile', () => {
    it('should update full name and phone number', async () => {
      builder.single
        .mockResolvedValueOnce({
          data: { id: testUserId, phone_number: '+919876543210', full_name: 'Haarhish' },
          error: null
        }) // Auth middleware check
        .mockResolvedValueOnce({
          data: { id: testUserId, full_name: 'Haarhish Updated', phone_number: '+919876543211' },
          error: null
        }); // Update query

      builder.maybeSingle
        .mockResolvedValueOnce({
          data: {
            id: testUserId,
            full_name: 'Haarhish Updated',
            phone_number: '+919876543211',
            trust_score: 96
          },
          error: null
        });

      const res = await request(app)
        .put('/api/profile')
        .set('Authorization', `Bearer ${testToken}`)
        .send({
          fullName: 'Haarhish Updated',
          phoneNumber: '+919876543211'
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.fullName).toBe('Haarhish Updated');
    });
  });

  describe('POST /api/profile/upload-image', () => {
    it('should upload profile picture to Cloudinary and update database', async () => {
      builder.single
        .mockResolvedValueOnce({
          data: { id: testUserId, phone_number: '+919876543210', full_name: 'Haarhish' },
          error: null
        }); // Auth check

      builder.maybeSingle
        .mockResolvedValueOnce({
          data: {
            id: testUserId,
            full_name: 'Haarhish',
            phone_number: '+919876543210',
            profile_image_url: 'https://res.cloudinary.com/doymxkmea/image/upload/v12345/car_rental/profiles/mock_avatar.jpg',
            trust_score: 96
          },
          error: null
        });

      const res = await request(app)
        .post('/api/profile/upload-image')
        .set('Authorization', `Bearer ${testToken}`)
        .attach('image', Buffer.from('mock image binary content'), 'avatar.jpg');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.profileImageUrl).toContain('mock_avatar.jpg');
    });
  });
});
