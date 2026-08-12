// auth.test.js
const request = require('supertest');
const bcrypt = require('bcrypt');
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
    single: mockSingle,
    maybeSingle: mockMaybeSingle,
    
    _data: null,
    _error: null,
    then(onFulfilled) {
      return Promise.resolve({ data: this._data, error: this._error }).then(onFulfilled);
    }
  };

  const mockAdmin = {
    listUsers: jest.fn(),
    createUser: jest.fn()
  };

  return {
    supabase: {
      from: jest.fn(() => mockQueryBuilder),
      auth: {
        admin: mockAdmin
      }
    },
    supabaseAnon: {}
  };
});

describe('Authentication Module Tests (Mobile OTP)', () => {
  let builder;

  beforeEach(() => {
    jest.clearAllMocks();
    builder = supabase.from();
    builder._data = null;
    builder._error = null;
  });

  describe('POST /api/auth/send-otp', () => {
    it('should generate and send OTP successfully', async () => {
      builder._data = [];
      builder._error = null;
      
      const res = await request(app)
        .post('/api/auth/send-otp')
        .send({ phoneNumber: '+1234567890' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toBe('OTP sent successfully');
      expect(res.body.data).toHaveProperty('otp');
    });

    it('should block OTP generation if rate limit is exceeded', async () => {
      builder._data = [{ created_at: 'now' }, { created_at: 'now' }, { created_at: 'now' }];
      builder._error = null;

      const res = await request(app)
        .post('/api/auth/send-otp')
        .send({ phoneNumber: '+1234567890' });

      expect(res.status).toBe(429);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Too many attempts');
    });
  });

  describe('POST /api/auth/verify-otp', () => {
    it('should verify correct OTP successfully and log in existing user', async () => {
      const plainOtp = '123456';
      const hashedOtp = await bcrypt.hash(plainOtp, 10);
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

      // 1. Set the mock response data for select OTP (direct array fetch)
      builder._data = [{
        id: 'otp-id',
        otp_code: hashedOtp,
        expires_at: expiresAt,
        is_verified: false,
        attempts: 0
      }];

      // 2. Mock checking user profile exists (calls maybeSingle)
      builder.maybeSingle.mockResolvedValueOnce({
        data: { id: 'user-id', phone_number: '+1234567890', full_name: 'John Doe' },
        error: null
      });

      // 3. Mock updating OTP record or user profiles (calls single)
      builder.single.mockResolvedValue({ data: { id: 'otp-id', is_verified: true }, error: null });

      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ phoneNumber: '+1234567890', otp: plainOtp });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('token');
      expect(res.body.data.isNewUser).toBe(false);
      expect(res.body.data.user.full_name).toBe('John Doe');
    });

    it('should reject incorrect OTP and increment failed attempts', async () => {
      const hashedOtp = await bcrypt.hash('654321', 10);
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

      builder._data = [{
        id: 'otp-id',
        otp_code: hashedOtp,
        expires_at: expiresAt,
        is_verified: false,
        attempts: 1
      }];

      builder.single.mockResolvedValueOnce({ error: null });

      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ phoneNumber: '+1234567890', otp: '000000' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Invalid OTP');
    });

    it('should reject verification if OTP code is expired', async () => {
      const hashedOtp = await bcrypt.hash('123456', 10);
      const expiredTime = new Date(Date.now() - 1000).toISOString();

      builder._data = [{
        id: 'otp-id',
        otp_code: hashedOtp,
        expires_at: expiredTime,
        is_verified: false,
        attempts: 0
      }];

      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ phoneNumber: '+1234567890', otp: '123456' });

      expect(res.status).toBe(410);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('expired');
    });

    it('should lock out user if attempts exceed 5', async () => {
      const hashedOtp = await bcrypt.hash('123456', 10);
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

      builder._data = [{
        id: 'otp-id',
        otp_code: hashedOtp,
        expires_at: expiresAt,
        is_verified: false,
        attempts: 5
      }];

      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ phoneNumber: '+1234567890', otp: '123456' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('locked');
    });
  });
});
