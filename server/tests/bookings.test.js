// bookings.test.js
const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../src/app');
const { supabase } = require('../src/config/supabase');
const env = require('../src/config/env');
const pricingService = require('../src/modules/bookings/pricing.service');
const cancellationService = require('../src/modules/bookings/cancellation.service');
const stateMachine = require('../src/modules/bookings/booking.state-machine');
const { expirePendingBookings } = require('../src/modules/bookings/jobs/expire-pending-bookings.cron');

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

describe('Bookings Module Tests', () => {
  let testToken;
  const renterId = 'renter-uuid-555';
  const ownerId = 'owner-uuid-777';
  let builder;

  beforeAll(() => {
    const payload = {
      aud: 'authenticated',
      sub: renterId,
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

  describe('Pricing Discounts Logic', () => {
    const pricePerDay = 100;
    const depositAmount = 200;

    it('should charge base price with 0% discount for bookings under 7 days', () => {
      const result = pricingService.calculatePricing(pricePerDay, depositAmount, '2026-08-04', '2026-08-06');
      expect(result.days).toBe(2);
      expect(result.discountPercentage).toBe(0);
      expect(result.totalPrice).toBe(200);
      expect(result.depositAmount).toBe(200);
    });

    it('should apply 5% discount for bookings between 7 and 29 days', () => {
      const result = pricingService.calculatePricing(pricePerDay, depositAmount, '2026-08-04', '2026-08-11');
      expect(result.days).toBe(7);
      expect(result.discountPercentage).toBe(5);
      expect(result.totalPrice).toBe(665);
    });

    it('should apply 10% discount for bookings 30 days and over', () => {
      const result = pricingService.calculatePricing(pricePerDay, depositAmount, '2026-08-01', '2026-08-31');
      expect(result.days).toBe(30);
      expect(result.discountPercentage).toBe(10);
      expect(result.totalPrice).toBe(2700);
    });
  });

  describe('Booking State Machine Transitions', () => {
    it('should validate allowed status transitions', () => {
      expect(stateMachine.isValidTransition('pending', 'confirmed')).toBe(true);
      expect(stateMachine.isValidTransition('pending', 'cancelled')).toBe(true);
      expect(stateMachine.isValidTransition('confirmed', 'active')).toBe(true);
      expect(stateMachine.isValidTransition('active', 'completed')).toBe(true);
    });

    it('should reject invalid status transitions', () => {
      expect(stateMachine.isValidTransition('pending', 'active')).toBe(false);
      expect(stateMachine.isValidTransition('pending', 'completed')).toBe(false);
      expect(stateMachine.isValidTransition('confirmed', 'completed')).toBe(false);
      expect(stateMachine.isValidTransition('completed', 'active')).toBe(false);
      expect(stateMachine.isValidTransition('active', 'cancelled')).toBe(false);
    });
  });

  describe('Cancellation Fee Tiers (Renter Initiated)', () => {
    const booking = {
      total_price: 1000,
      deposit_amount: 300,
      start_date: '2026-08-10'
    };

    it('should charge 0% cancellation fee at 72 hours before start', () => {
      jest.useFakeTimers().setSystemTime(new Date('2026-08-07T00:00:00Z'));
      
      const result = cancellationService.calculateCancellation(booking, 'renter');
      expect(result.cancellationFee).toBe(0);
      expect(result.refundAmount).toBe(1300);
    });

    it('should charge 50% cancellation fee at 30 hours before start', () => {
      jest.useFakeTimers().setSystemTime(new Date('2026-08-08T18:00:00Z'));
      
      const result = cancellationService.calculateCancellation(booking, 'renter');
      expect(result.cancellationFee).toBe(500);
      expect(result.refundAmount).toBe(800);
    });

    it('should charge 100% cancellation fee at 10 hours before start', () => {
      jest.useFakeTimers().setSystemTime(new Date('2026-08-09T14:00:00Z'));
      
      const result = cancellationService.calculateCancellation(booking, 'renter');
      expect(result.cancellationFee).toBe(1000);
      expect(result.refundAmount).toBe(300);
      
      jest.useRealTimers();
    });

    it('should issue full refund and zero fee on owner-initiated cancellation', () => {
      const result = cancellationService.calculateCancellation(booking, 'owner');
      expect(result.cancellationFee).toBe(0);
      expect(result.refundAmount).toBe(1300);
    });
  });

  describe('POST /api/bookings (Exclusion & Overlap Verification)', () => {
    it('should return 409 Conflict when database raises exclusion overlap error (23P01)', async () => {
      // 1. Mock profile query step inside auth protect middleware
      builder.single.mockResolvedValueOnce({ data: { id: renterId }, error: null });

      // 2. Mock vehicle details query step in booking validation
      builder.maybeSingle.mockResolvedValueOnce({
        data: {
          id: 'vehicle-id',
          owner_id: 'different-owner-id',
          status: 'active',
          is_available: true,
          price_per_day: 100,
          deposit_amount: 200
        },
        error: null
      });

      // 3. Mock booking insertion returning overlap error
      const pgError = new Error('exclusion constraint overlap');
      pgError.code = '23P01';
      builder.single.mockRejectedValueOnce(pgError);

      const res = await request(app)
        .post('/api/bookings')
        .set('Authorization', `Bearer ${testToken}`)
        .send({
          vehicleId: 'vehicle-id',
          startDate: '2026-08-10',
          endDate: '2026-08-15'
        });

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Double-booking conflict');
    });
  });

  describe('Auto-Expire Pending Bookings Cron Job', () => {
    it('should find and expire pending unpaid bookings older than 15 minutes', async () => {
      const staleBooking = { id: 'booking-stale-1', total_price: 500, deposit_amount: 100 };
      
      // 1. Set mock query builder data for cron query
      builder._data = [staleBooking];
      builder._error = null;

      await expirePendingBookings();

      // Check if update call was fired to cancel the stale booking
      expect(builder.update).toHaveBeenCalledWith(expect.objectContaining({
        status: 'cancelled',
        cancelled_by: 'system'
      }));
    });
  });
});
